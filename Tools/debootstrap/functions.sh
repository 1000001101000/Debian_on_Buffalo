
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

write_word()
{
  word $1 $2 >> tmpsb.bin
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

write_word 0xa92b4efc > tmpsb.bin #mdadm magic
write_word 0
write_word 90
write_word 0
write_word 0
write_word $uuid1	 ## uuid first write_word
write_word $date	 ##create date
write_word 1		 ##just raid1
write_word $size
write_word 1		 ##nr disks, just 1 for this use case
write_word 1		 ##aspirational number, also 1 for this
write_word $((part-1)) ##md dev num, ex md127
write_word 0
write_word $uuid2	 ##the rest of the uuid
write_word $uuid3
write_word $uuid4
write_word 0 16
write_word $date	 ##same as create since it's not actually run
write_word 0x0101	 ## state clean + ?
write_word 1		 ## 1 of 1 active disk
write_word 1		 ## 1 of 1 working
write_word 0		 ## 0 failed
write_word 0		 ## 0 spare
write_word 0		 ## backfill with checksum of 4k superblock

###endian dependent for 0.90 fyi
write_word 2		 ## event checkpoint counter 2 matching one created by mdadm
write_word 0		 ## low bits of counter
write_word 2		 ## set update counter the same, all 1 disks are in sync!
write_word 0		 ## low bits of counter

write_word -1		 ## FFFF in example
write_word 0 6	 ##stuff that needs to be imp for > v0.90
write_word 0 18
write_word 0 8	 ##stuff that doesn't apply to raid1, chunk etc

write_word 0 52	 ##space for a bunch of reserved stuff

##padding for all the theoretical drives that could be added.
for ((j=0;j<=27;j++))
do
if [ $j -eq 27 ] || [ $j -eq 0 ]; then
###details of the disk, one for it's role in the array and one for itself
write_word 0		 ## disk number in the array
write_word $dev_major	 ##disk major num , sda1/etc?
write_word $dev_minor	 ##disk minor num
write_word 0		 ## role in array
write_word 6		 ## state, active sync
write_word 0 27	 ## reserved
else
  write_word 0 32
fi
done

###write the checksum to the proper bytes
word $rollingcrc | dd of=tmpsb.bin bs=4 seek=38 conv=notrunc 2>/dev/null

##now populate a blank bitmap, or rework this to not create it?
##explicitly little endian by the sound of it.
write_word 0x6d746962	 ##bitmap magic
write_word 4		 ##bitmap version
write_word $uuid1	 ##UUID matching the mdadm superblock
write_word $uuid2
write_word $uuid3
write_word $uuid4
write_word 2		 ## event counter
write_word 0		 ## counter lower bits
write_word 1		 ## last cleared counter?
write_word 0		 ## counter lower bits
write_word 0x100780	 ## sync size upper
write_word 0		 ## sync size lower
write_word 0		 ## state?
write_word 0x04000000	 ## bitmap chunk size
write_word 5		 ## daemon sleep
write_word 0		 ## write behind
write_word 0		 ## reserved sectors
write_word 0		 ## cluster nodes
write_word 0 16	 ## cluster name
write_word 0 30	 ## padding
write_word 0xfffffe00	 ## I think 16bit size of bitmap and first bytes of it?
write_word -1 $((0x3bbf))  ## need to look at numbers etc. probably some padding to 16k as part of this.
}
