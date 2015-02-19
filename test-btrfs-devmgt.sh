# * GNU General Public License v2. Copyright Oracle 2015


# Series of btrfs device operation test cases.
#

# sysfs: test
# sysfs contents are taken at reasonable places (but you may disable it).
# So to compare with the next iteration with your kernel patch. so
# you can check for the sysfs changes by running diff of TMP_FILE(s)


		#When you change something related to device
		#remember to test on btrfs boot separately
 #test0: btrfs boot test

		#Replace:
 #test1: raid1, replace normal
 #test2: raid1, replace missing
 #test3: NOP
 #test4: raid1, replace missing, replace normal
 #test5: raid1, replace dev2, replace dev1

		#Add sprout, replace:
 #test6: add sprout, replace seed
 #test7: raid1 seed, add sprout, replace seed, replace sprout
 #test8: 3 level nested seeds, add sprout, replace mid level seed
 #test9: raid1, degraded seed mount, add sprout, replace missing, replace non missing seed
 #test10: add sprout, replace sprout
 #test11: raid1 seed, add sprout, replace sprout, replace sprout again
 #test12: 3 level nested seeds, add sprout, replace sprout
 #test13: degraded raid1 seed, add sprout, replace sprout

		#Mount sprout, replace:
 #test14: NOP
 #test15: mount sprout, replace sprout
 #test16: mount sprout, replace seed
 #test17: Raid1, mount sprout, replace sprout
 #test18: Raid1, mount sprout, replace seed
 #test19: Raid1 degraded, mount sprout, replace sprout
 #test20: Raid1 degraded, mount sprout, replace missing
 #test21: 3 level nested seeds, mount sprout, replace mid level seed

		#seed sprout test:
 #test22: mount sprout, mount seed
 #test23: clean, mount -o device sprout
 #test24: raid1, mount sprout
 #test25: clean, scan, mount sprout
 #test26: raid1, clean, mount -o device sprout
 #test26: raid1, clean, scan, mount sprout

		#dev add del test:
 #test27: dev add
 #test28: dev del

		#dev scan test:
 #test29: scan mount
 #test30: use -o mount

		#subvol mount test:
 #test31: mount, mount subvol

		#remount test:
 #test32: mount, remount

		#add sprout test:
 #test33: add sprout
 #test34: raid1 seed, add sprout
 #test35: add sprout, umount, mount seed, mount sprout

 #test36: simple, mkfs, mount


# Devices are hard coded. sorry

# Assign per your config, all 5 needed, replace might fail
# if DEV5 < DEV4 < DEV3 < DEV2 < DEV1
DEV1=/dev/sdd
DEV2=/dev/sde
DEV3=/dev/sdf
DEV4=/dev/sdg
DEV5=/dev/sdc

[[ -z $DEV1 ]] || [[ -z $DEV2 ]] || [[ -z $DEV3 ]] || [[ -z $DEV4 ]] || [[ -z $DEV5 ]] && echo "Need to initialize DEVx as above here" && exit

TEST_FSID=1c52f894-0ead-43d6-847a-d42359f78370

#Enable or disable sysfs data collection by set/unset the below
#TMP_FILE=''
TMP_FILE=`mktemp`

#If the btrfs is root fs as well then set this
#CANT_CLEAN='yes'

ent_cont()
{
	echo -n "Done. Enter to continue: "
	#read
	echo "wait for input is disabled, uncomment above to wait."
}

erase()
{
	for i in $DEV1 $DEV2 $DEV3 $DEV4 $DEV5; do wipefs -a $i > /dev/null; done
}

clean()
{
	[[ -z $CANT_CLEAN ]] && return

	! modprobe -r btrfs && echo "For btrfs boot set CANT_CLEAN to yes here above" && exit
	modprobe btrfs
}

collect_sysfs()
{
	# see above to disable sysfs data collection
	[[ -z $TMP_FILE ]] && return

	echo ---------------- $1 ------------- >> $TMP_FILE
	find /sys/fs/btrfs -type f -exec cat {} \; -print >> $TMP_FILE
}

_mkfs.btrfs()
{
	mkfs.btrfs $* > /dev/null
}


test1()
{
	TEST="test1"
	erase
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -d raid1 -m raid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID -draid1 -mraid1 $DEV1 $DEV2 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	TEST="test24" && erase && echo -e "\n$TEST"

_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f

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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f
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

test27()
{
	TEST="test27"
	erase
	echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f
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
	TEST="test28" && erase && echo -e "\n$TEST"

_mkfs.btrfs -dsingle -msingle -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f
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
	TEST="test29" && erase && echo -e "\n$TEST"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -dsingle -msingle -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f
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
	TEST="test30" && erase && echo -e "\n$TEST"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -dsingle -msingle -L $TEST -U $TEST_FSID $DEV1 $DEV2 $DEV3 -f
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
	TEST="test31" && erase && echo -e "\n$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	TEST="test32" && erase && echo -e "\n$TEST"

_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	TEST="test33" && erase && echo -e "\n$TEST"

	collect_sysfs "$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	TEST="test34" && erase && echo -e "\n$TEST"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -draid1 -mraid1 -L $TEST -U $TEST_FSID $DEV1 $DEV2 -f
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
	TEST="test35" && erase && echo -e "\n$TEST"
clean
	collect_sysfs "$TEST"
_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 -f
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
	TEST="test36" && erase && echo -e "\n$TEST"

_mkfs.btrfs -L $TEST -U $TEST_FSID $DEV1 $DEV2

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
  echo "Have you tested with btrfs boot, you can't do that here\n"
}

clean

# Due to a bug in the ref below, don't enable 6-21 yet.
#   ref: email: Sub: "replace seed/sprout hangs (regression ?)"
#sleep 2; test6
#sleep 2; test7
#sleep 2; test8
#sleep 2; test9
#sleep 2; test9
#sleep 2; test10
#sleep 2; test11
#sleep 2; test12
#sleep 2; test13

#sleep 2; test14
#sleep 2; test15
#sleep 2; test16
#sleep 2; test17
#sleep 2; test18
#sleep 2; test19
#sleep 2; test20
#sleep 2; test21

sleep 2; test36

#sleep 2; test29
#sleep 2; test30
#sleep 2; test31
#sleep 2; test32
#sleep 2; test33
#sleep 2; test34
#sleep 2; test35

#sleep 2; test22
#sleep 2; test23
#sleep 2; test24
#sleep 2; test25
#sleep 2; test26

#sleep 2; test27
#sleep 2; test28

#sleep 2; test1
#sleep 2; test2
#sleep 2; test3
#sleep 2; test4
#sleep 2; test5


[[ -z $TMP_FILE ]] || echo -e "\nTMP_FILE= $TMP_FILE"
