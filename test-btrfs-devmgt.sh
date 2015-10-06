# * GNU General Public License v2. Copyright Oracle 2015


# Series of btrfs device operation test cases.
#

# sysfs: test
# sysfs contents are taken at reasonable places (but you may disable it).
# So to compare with the next iteration with your kernel patch. so
# you can check for the sysfs changes by running diff of TMP_FILE(s)


# Devices are hard coded. sorry

# Assign per your config, all 5 needed, replace might fail
# if DEV5 < DEV4 < DEV3 < DEV2 < DEV1
#DEV1=/dev/sdc
#DEV2=/dev/sdd
#DEV3=/dev/sde
#DEV4=/dev/sdf
#DEV5=/dev/sdg


#Enable or disable sysfs data collection by set/unset the below
#TMP_FILE=''
TMP_FILE=`mktemp`

#If the btrfs is root fs as well then set this
SKIP_CLEAN='yes'

TEST_FSID=1c52f894-0ead-43d6-847a-d42359f78370

[[ -z $DEV1 ]] || [[ -z $DEV2 ]] || [[ -z $DEV3 ]] || [[ -z $DEV4 ]] || [[ -z $DEV5 ]] && echo "Need to initialize DEVx as above here" && exit

ent_cont()
{
	echo -n "Done. Enter to continue: "
	#read
	echo "wait for input is disabled, uncomment above to wait."
}

erase()
{
	#for i in $DEV1 $DEV2 $DEV3 $DEV4 $DEV5; do wipefs -a $i > /dev/null; done
}

clean()
{
	! [[ -z $SKIP_CLEAN ]] && return

	! modprobe -r btrfs && echo "For btrfs boot set CANT_CLEAN to yes here above" && exit
	modprobe btrfs
}

collect_sysfs()
{
	# see above to disable sysfs data collection
	[[ -z $TMP_FILE ]] && return

	echo ---------------- $TEST ------------- >> $TMP_FILE
	find /sys/fs/btrfs -type f -exec cat {} \; -print >> $TMP_FILE || exit
}

_mkfs.btrfs()
{
	LABEL=$TEST
	mkfs.btrfs -L $LABEL -U $TEST_FSID $* > /dev/null
	#mkfs.btrfs -L $LABEL $* > /dev/null
}

__log()
{
	echo -e "\n$TEST $1"
}


test1()
{
	TEST="test1"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
	collect_sysfs "$TEST"
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test2()
{
	TEST="test2"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
	clean
mount -o degraded $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B 2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test4()
{
	TEST="test4"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
	clean
mount -o degraded $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B 2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV1 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test5()
{
	TEST="test5"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV1 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}


##### Seed device test cases replace the seed device ###########
test6()
{
	TEST="test6"
	erase
	__log "$1"
_mkfs.btrfs $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs -f
	collect_sysfs "$TEST"
btrfs repl start -B $DEV1 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test7()
{
	TEST="test7"
	erase
	__log "$1"
_mkfs.btrfs -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV1 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV2 $DEV5 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test8()
{
	TEST="test8"
	erase
	__log "$1"
_mkfs.btrfs $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV2
mount $DEV2 /btrfs1
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs1 -f
	collect_sysfs "$TEST"
umount /btrfs1
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV3
mount $DEV3 /btrfs2
	collect_sysfs "$TEST"
btrfs dev add $DEV4 /btrfs2 -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV2 $DEV5 /btrfs2 -f
	collect_sysfs "$TEST"
umount /btrfs2
	collect_sysfs "$TEST"
mount $DEV5 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test9()
{
	TEST="test9"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV1
	clean
mount -o degraded $DEV1 /btrfs
	collect_sysfs "$TEST"
	echo -e add
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
	echo -e replace1
btrfs rep start -B 2 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
	echo -e replace2
btrfs rep start -B $DEV1 $DEV5 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

##### Seed device test cases replace the sprout device ###########
test10()
{
	TEST="test10"
	erase
	__log "$1"
_mkfs.btrfs $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs -f
	collect_sysfs "$TEST"
btrfs repl start -B $DEV2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test11()
{
	TEST="test11"
	erase
	__log "$1"
_mkfs.btrfs -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV3 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV4 $DEV5 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test12()
{
	TEST="test12"
	erase
	__log "$1"
_mkfs.btrfs $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV2
mount $DEV2 /btrfs1
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs1 -f
	collect_sysfs "$TEST"
umount /btrfs1
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV3
mount $DEV3 /btrfs2
	collect_sysfs "$TEST"
btrfs dev add $DEV4 /btrfs2 -f
	collect_sysfs "$TEST"
btrfs rep start -B $DEV4 $DEV5 /btrfs2 -f
	collect_sysfs "$TEST"
umount /btrfs2
	collect_sysfs "$TEST"
mount $DEV5 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test13()
{
	TEST="test13"
	erase
	__log "$1"
_mkfs.btrfs -d raid1 -m raid1 $DEV1 $DEV2 -f
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV1
	clean
mount -o degraded $DEV1 /btrfs
	collect_sysfs "$TEST"
	echo -e add
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
	echo -e replace1
btrfs rep start -B $DEV3 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}


test15()
{
	TEST="test15"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV1 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test16()
{
	TEST="test16"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV2 $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test17()
{
	TEST="test17"
	erase
	__log "$1"
_mkfs.btrfs  -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV3 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test18()
{
	TEST="test18"
	erase
	__log "$1"
_mkfs.btrfs  -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV1 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test19()
{
	TEST="test19"
	erase
	__log "$1"
_mkfs.btrfs  -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
mount -o degraded -o device=$DEV2 $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B $DEV3 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test20()
{
	TEST="test20"
	erase
	__log "$1"
_mkfs.btrfs  -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
mount -o degraded -o device=$DEV2 $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs rep start -B 1 $DEV4 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test21()
{
	TEST="test21"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV2
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV3
mount $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV4 /btrfs2 -f
	collect_sysfs "$TEST"
umount /btrfs
mount $DEV4 /btrfs
btrfs rep start -B $DEV2 $DEV5 /btrfs -f
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV5 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test22()
{
	TEST="test22"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
mount $DEV1 /btrfs1
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
umount /btrfs1
	collect_sysfs "$TEST"
	clean
	ent_cont
}


test23()
{
	TEST="test23"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"

	clean

mount -o device=$DEV1 $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test24()
{
	TEST="test24" && erase && __log "$1"

_mkfs.btrfs  $DEV1 $DEV2 -f

btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test25()
{
	TEST="test25"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"

	clean

btrfs dev scan
mount $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test26()
{
	TEST="test26"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"

	clean

mount -o device=$DEV1 -o device=$DEV2 $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test37()
{
	TEST="test37"
	erase
	__log "$1"
_mkfs.btrfs  -draid1 -mraid1 $DEV1 $DEV2 -f
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"

	clean

btrfs dev scan
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	clean
	ent_cont
}

test27()
{
	TEST="test27"
	erase
	__log "$1"
_mkfs.btrfs  $DEV1 $DEV2 -f
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs
	collect_sysfs "$TEST"
btrfs dev del $DEV1 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
	ent_cont
}

test28()
{
	TEST="test28" && erase && __log "$1"

_mkfs.btrfs -dsingle -msingle  $DEV1 $DEV2 -f
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev del $DEV1 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"

	ent_cont
}

test29()
{
	TEST="test29" && erase && __log "$1"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -dsingle -msingle  $DEV1 $DEV2 -f
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"
btrfs dev scan
	collect_sysfs "$TEST"
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont

}

test30()
{
	TEST="test30" && erase && __log "$1"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -dsingle -msingle  $DEV1 $DEV2 $DEV3 -f
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"
mount -o device=$DEV1,device=$DEV2 $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}

test31()
{
	TEST="test31" && erase && __log "$1"
_mkfs.btrfs  $DEV1 -f
	collect_sysfs "$TEST"
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs su create /btrfs/sv1
mount -o subvol=sv1 $DEV1 /btrfs1
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
umount /btrfs1
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}

test32()
{
	TEST="test32" && erase && __log "$1"

_mkfs.btrfs  $DEV1 -f
	collect_sysfs "$TEST"
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
mount -o remount /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}

test33()
{
	TEST="test33" && erase && __log "$1"

	collect_sysfs "$TEST"
_mkfs.btrfs  $DEV1 -f
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}

test34()
{
	TEST="test34" && erase && __log "$1"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -draid1 -mraid1  $DEV1 $DEV2 -f
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV3 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}

test35()
{
	TEST="test35" && erase && __log "$1"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs  $DEV1 -f
	collect_sysfs "$TEST"
btrfstune -S 1 $DEV1
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
btrfs dev add $DEV2 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
mount $DEV2 /btrfs1
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
umount /btrfs1
clean
	collect_sysfs "$TEST"

	ent_cont
}

test36()
{
	TEST="test36" && erase && __log "$1"

_mkfs.btrfs  $DEV1 $DEV2
	collect_sysfs "$TEST"
mount $DEV1 /btrfs
	collect_sysfs "$TEST"
umount /btrfs
	collect_sysfs "$TEST"
clean
	collect_sysfs "$TEST"

	ent_cont
}


test0()
{
  echo "Have you tested with btrfs boot ?"
}


run_seed_sprout_replace_unsupported()
{
# Due to a bug in the ref below, don't enable 6-21 yet.
#   ref: email: Sub: "replace seed/sprout hangs (regression ?)"
		#Add sprout, replace:
test6 "#: add sprout, replace seed"
test7  "#: raid1 seed, add sprout, replace seed, replace sprout"
test8  "#: 3 level nested seeds, add sprout, replace mid level seed"
test9  "#: raid1, degraded seed mount, add sprout, replace missing, replace non missing seed"
test10  "#: add sprout, replace sprout"
test11  "#: raid1 seed, add sprout, replace sprout, replace sprout again"
test12  "#: 3 level nested seeds, add sprout, replace sprout"
test13  "#: degraded raid1 seed, add sprout, replace sprout"

		#Mount sprout, replace:
test14  "#: NOP"
test15  "#: mount sprout, replace sprout"
test16  "#: mount sprout, replace seed"
test17  "#: Raid1, mount sprout, replace sprout"
test18  "#: Raid1, mount sprout, replace seed"
test19  "#: Raid1 degraded, mount sprout, replace sprout"
test20  "#: Raid1 degraded, mount sprout, replace missing"
test21  "#: 3 level nested seeds, mount sprout, replace mid level seed"
}

run_scan_mount_test()
{
		#dev scan test, mount test
test36  "#: simple, mkfs, mount"
test29  "#: scan mount"
test30  "#: use -o mount to scan"
		#subvol mount test:
test31  "#: mount, mount subvol"
		#remount test:
test32  "#: mount, remount"

		#dev add del test:
#test27  "#: dev add"
#test28  "#: dev del"
}

run_replace_tests()
{
		#Replace:
test1  "#: raid1, replace normal"
test2  "#: raid1, replace missing"
test3  "#: NOP"
test4  "#: raid1, replace missing, replace normal"
test5  "#: raid1, replace dev2, replace dev1"
}

run_seed_sprout_tests()
{
		#seed sprout test:
test22  "#: mount sprout, mount seed"
test23  "#: clean, mount -o device sprout"
test24  "#: raid1, mount sprout"
test25  "#: clean, scan, mount sprout"
test26  "#: raid1, clean, mount -o device sprout"
test37  "#: raid1, clean, scan, mount sprout"
		#add sprout test:
test33  "#: add sprout"
test34  "#: raid1 seed, add sprout"
test35  "#: add sprout, umount, mount seed, mount sprout"
}

#### Actual testing begins here #####
clean
		#When you change something related to device
		#remember to test on btrfs boot separately
#test0  "#: btrfs boot test

run_scan_mount_test
run_replace_tests
run_seed_sprout_tests
#run_seed_sprout_replace_unsupported

[[ -z $TMP_FILE ]] || echo -e "\nTMP_FILE= $TMP_FILE"
