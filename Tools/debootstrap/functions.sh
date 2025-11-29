
rollingcrc=0

gh_user="1000001101000"
gh_repo="Debian_on_Buffalo"
gh_branch="master"
gh_url="https://raw.githubusercontent.com/$gh_user/$gh_repo/refs/heads/$gh_branch/"

gh_download_chroot()
{
  local source="$gh_url$1"
  local dest="$2"

  chroot "$target" /bin/bash -c "wget -O $dest $source" >>$log 2>&1
  if [ $? -ne 0 ]; then
    echo "installation of $(basename $dest) failed, check log for details"
    exit 99
  fi
}

uuidgen_chroot()
{
  chroot "$target" "uuidgen"
}

##think I did something kinda similar but worse in the realtek firmware stuff.
##expanding to u32/u64/le32 etc might be fun
word()
{
  ####can add endianness option later if needed
  local UINT32_VALUE=$1
  local repeat=$2
  [ -z $repeat ] && repeat=1
  local format=0
  local i=0
  local BYTE0=$(( UINT32_VALUE & 0xFF ))
  local BYTE1=$(( (UINT32_VALUE >> 8) & 0xFF ))
  local BYTE2=$(( (UINT32_VALUE >> 16) & 0xFF ))
  local BYTE3=$(( (UINT32_VALUE >> 24) & 0xFF ))

  printf -v format '\\x%02x\\x%02x\\x%02x\\x%02x' "$BYTE0" "$BYTE1" "$BYTE2" "$BYTE3"
  for ((i=1;i<=repeat;i++))
  do
    printf $format
    rollingcrc=$(( rollingcrc + (UINT32_VALUE & 0xFFFFFFFF) ))
    rollingcrc=$(( ($rollingcrc & 0xFFFFFFFF) + ($rollingcrc>>32) ))
  done
}


gen_raid1_sb()
{
local part=$1
local uuid="$2"
local size="$3"
local dev_major=8
local dev_minor=$part

size=$(( (size) & 0xFFFF0000 )) ##parition size rounded down to 64k aligned
size=$(( (size/1024) - 64 )) #subtract 64k, convert to kilobyte
##superblock goes at last 64k aligned address, effective size is everything before that.
local date=$(date +%s)
local uuid1="0x${uuid:0:8}"
local uuid2="0x${uuid:9:4}${uuid:14:4}"
local uuid3="0x${uuid:19:4}${uuid:24:4}"
local uuid4="0x${uuid:28:8}"

rollingcrc=0

word 0xa92b4efc > test.bin
word 0		>> test.bin
word 90		>> test.bin
word 0		>> test.bin
word 0          >> test.bin
word $uuid1	>> test.bin ##need real uuid
word $date	>> test.bin ##create date
word 1		>> test.bin ##just raid1
word $size	>> test.bin ##need size
word 1		>> test.bin ##nr disks, just 1 for this use case
word 1		>> test.bin ##aspirational number, also 1 for this
word $((part-1))>> test.bin ##md dev num, ex md127
word 0 		>> test.bin
word $uuid2	>> test.bin ##the rest of the uuid, related to hostname?
word $uuid3	>> test.bin
word $uuid4	>> test.bin
word 0 16	>> test.bin
word $date	>> test.bin ##same as create since it's not actually run
word 0x0101	>> test.bin ## state clean + ?
word 1		>> test.bin ## 1 of 1 active disk
word 1		>> test.bin ## 1 of 1 working
word 0		>> test.bin ## 0 failed
word 0		>> test.bin ## 0 spare
word 0		>> test.bin ## backfill with checksum of 4k superblock

###endian dependent for 0.90 fyi
word 2		>> test.bin ## event checkpoint counter 2 matching one created by mdadm
word 0		>> test.bin ## low bits of counter
word 2		>> test.bin ## set update counter the same, all 1 disks are in sync!
word 0		>> test.bin ## low bits of counter

word -1		>> test.bin ## FFFF in example
word 0 6	>> test.bin ##stuff that needs to be imp for > v0.90
word 0 18	>> test.bin
word 0 8	>> test.bin ##stuff that doesn't apply to raid1, chunk etc

word 0 52	>> test.bin ##space for a bunch of reserved stuff

##padding for all the theoretical drives that could be added.
for ((j=0;j<=27;j++))
do
if [ $j -eq 27 ] || [ $j -eq 0 ]; then
###details of the disk, one for it's role in the array and one for itself
word 0		>> test.bin ## disk number in the array
word $dev_major	>> test.bin ##disk major num , sda1/etc?
word $dev_minor	>> test.bin ##disk minor num
word 0		>> test.bin ## role in array
word 6		>> test.bin ## state, active sync
word 0 27	>> test.bin ## reserved
else
  word 0 32	>> test.bin
fi
done

###write the checksum to the proper bytes
word $rollingcrc | dd of=test.bin bs=4 seek=38 conv=notrunc 2>/dev/null

##now populate a blank bitmap, or rework this to not create it?
##explicitly little endian by the sound of it.
word 0x6d746962	>> test.bin ##bitmap magic
word 4		>> test.bin ##bitmap version
word $uuid1	>> test.bin ##UUID matching the mdadm superblock
word $uuid2	>> test.bin
word $uuid3	>> test.bin
word $uuid4	>> test.bin
word 2		>> test.bin ## event counter
word 0		>> test.bin ## counter lower bits
word 1		>> test.bin ## last cleared counter?
word 0		>> test.bin ## counter lower bits
word 0x100780	>> test.bin ## sync size upper
word 0		>> test.bin ## sync size lower
word 0		>> test.bin ## state?
word 0x04000000	>> test.bin ## bitmap chunk size
word 5		>> test.bin ## daemon sleep
word 0		>> test.bin ## write behind
word 0		>> test.bin ## reserved sectors
word 0		>> test.bin ## cluster nodes
word 0 16	>> test.bin ## cluster name
word 0 30	>> test.bin ## padding
word 0xfffffe00	>> test.bin ## I think 16bit size of bitmap and first bytes of it?
word -1 $((0x3bbf)) >> test.bin ## need to look at numbers etc. probably some padding to 16k as part of this.
#mdadm -E test.bin
##chance to bail before writing nonesense?
##need to write to last 64k aligned address
#dd if=test.bin of="$image" bs=64k count=1 seek=$(( (start*sectorsz) + (size*1024) )) oflag=seek_bytes conv=notrunc
#rm test.bin
}

