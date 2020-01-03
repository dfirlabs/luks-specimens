#!/bin/bash
#
# Script to generate LUKS test files

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1;

	which ${BINARY} > /dev/null 2>&1;
	if test $? -ne ${EXIT_SUCCESS};
	then
		echo "Missing binary: ${BINARY}";
		echo "";

		exit ${EXIT_FAILURE};
	fi
}

# Creates test file entries.
#
# Arguments:
#   a string containing the path of the image file
#   a string containing the path of the key file
#
create_test_file_entries()
{
	local IMAGE_FILE=$1;
	local PASSWORD_FILE=$2;

	sudo cryptsetup luksOpen ${IMAGE_FILE} luks_test < ${PASSWORD_FILE};

	sudo mke2fs -q -t ext2 -L "ext2_test" /dev/mapper/luks_test;

	sudo mount -o loop,rw /dev/mapper/luks_test ${MOUNT_POINT};

	sudo chown ${USERNAME} ${MOUNT_POINT};

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	# Create a file
	echo "My file" > ${MOUNT_POINT}/testdir1/testfile1

	sudo umount ${MOUNT_POINT};

	sleep 1;

	sudo cryptsetup luksClose luks_test;
}

assert_availability_binary cryptsetup;
assert_availability_binary dd;

set -e;

SPECIMENS_PATH="specimens";

mkdir -p ${SPECIMENS_PATH};

MOUNT_POINT="/mnt/luks";

sudo mkdir -p ${MOUNT_POINT};

PASSWORD_FILE="specimens/password.txt";

echo "LUKStest" > ${PASSWORD_FILE};

IMAGE_SIZE=$(( 4096 * 1024 ));
SECTOR_SIZE=512;

# Known but not supported: arc4 cast5 tnepres
for NAME in aes anubis blowfish cast6 serpent twofish;
do
	IMAGE_NAME="${SPECIMENS_PATH}/luks1_${NAME}-ecb_sha1.raw"

	dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	cryptsetup --batch-mode --cipher ${NAME}-ecb --hash sha1 --type luks1 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

	create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};

	if test ${NAME} = "blowfish" || test ${NAME} = "cast6";
	then
		# Known but not supported: lmk tcw
		for IVMODE in benbi essiv:sha256 null plain plain64 plain64be;
		do
			IMAGE_NAME="${SPECIMENS_PATH}/luks1_${NAME}-cbc-${IVMODE}_sha1.raw"

			dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

			cryptsetup --batch-mode --cipher ${NAME}-cbc-${IVMODE} --hash sha1 --type luks1 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

			create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
		done
	else
		for MODE in cbc xts;
		do
			# Known but not supported: lmk tcw
			for IVMODE in benbi essiv:sha256 null plain plain64 plain64be;
			do
				IMAGE_NAME="${SPECIMENS_PATH}/luks1_${NAME}-${MODE}-${IVMODE}_sha1.raw"

				dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

				cryptsetup --batch-mode --cipher ${NAME}-${MODE}-${IVMODE} --hash sha1 --type luks1 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

				create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
			done
		done
	fi
done

for NAME in sha1 sha224 sha256 sha512 ripemd160;
do
	IMAGE_NAME="${SPECIMENS_PATH}/luks1_aes-ecb_${NAME}.raw"

	dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	cryptsetup --batch-mode --cipher aes-ecb --hash ${NAME} --type luks1 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

	create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
done

for NAME in aes anubis blowfish cast6 serpent twofish;
do
	IMAGE_NAME="${SPECIMENS_PATH}/luks2_${NAME}-ecb_sha1.raw"

	dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	cryptsetup --batch-mode --cipher ${NAME}-ecb --hash sha1 --type luks2 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

	# TODO: fix allow for "Requested offset is beyond real size of device"
	# create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};

	if test ${NAME} = "blowfish" || test ${NAME} = "cast6";
	then
		# Known but not supported: lmk tcw
		for IVMODE in benbi essiv:sha256 null plain plain64 plain64be;
		do
			IMAGE_NAME="${SPECIMENS_PATH}/luks2_${NAME}-cbc-${IVMODE}_sha1.raw"

			dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

			cryptsetup --batch-mode --cipher ${NAME}-cbc-${IVMODE} --hash sha1 --type luks2 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

			# TODO: fix allow for "Requested offset is beyond real size of device"
			# create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
		done
	else
		for MODE in cbc xts;
		do
			# Known but not supported: lmk tcw
			for IVMODE in benbi essiv:sha256 null plain plain64 plain64be;
			do
				IMAGE_NAME="${SPECIMENS_PATH}/luks2_${NAME}-${MODE}-${IVMODE}_sha1.raw"

				dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

				cryptsetup --batch-mode --cipher ${NAME}-${MODE}-${IVMODE} --hash sha1 --type luks2 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

				# TODO: fix allow for "Requested offset is beyond real size of device"
				# create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
			done
		done
	fi
done

for NAME in sha1 sha224 sha256 sha512 ripemd160;
do
	IMAGE_NAME="${SPECIMENS_PATH}/luks2_aes-ecb_${NAME}.raw"

	dd if=/dev/zero of=${IMAGE_NAME} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	cryptsetup --batch-mode --cipher aes-ecb --hash ${NAME} --type luks2 luksFormat ${IMAGE_NAME} < ${PASSWORD_FILE};

	# TODO: fix allow for "Requested offset is beyond real size of device"
	# create_test_file_entries ${IMAGE_NAME} ${PASSWORD_FILE};
done

exit ${EXIT_SUCCESS};

