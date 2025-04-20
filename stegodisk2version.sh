#!/bin/bash
set -e  # Завершить выполнение при ошибке

# Проверка наличия необходимых утилит
for cmd in losetup dmsetup mkfs.ext4 e2fsck sha512sum; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: Required command '$cmd' is not installed."
    exit 1
  fi
done

# Версия скрипта
version="0.2"

# Параметры
input_file=$1
mount_point=$2
cipher="serpent-xts-plain64"
sha="sha512sum"

# Функция для проверки существования файла
check_file() {
  if [[ -n "$input_file" && -f "$input_file" ]]; then
    file_ok="y"
  else
    echo "ERROR: File does not exist or is not specified."
    exit 1
  fi
}

# Функция для проверки маппинга устройства
check_map() {
  loop_device=$(losetup -j "$input_file" -O NAME -n | head -1)
  if [[ -n "$loop_device" ]]; then
    is_mapped="y"
  fi
}

# Функция для ввода пароля
enter_pass() {
  echo -n "Enter password: "
  read -s password
  echo 

  if [[ -z "$password" ]]; then
    echo "ERROR: Password cannot be empty."
    exit 1
  fi

  key=$(echo -n "$password" | $sha | awk '{print $1}')
  tmp=$(echo -n "$key" | $sha | awk '{print $1}')
}

# Функция для проверки и создания директории
check_dir() {
  if [[ -z "$mount_point" ]]; then
    echo -n "Enter mountpoint: "
    read mount_point
  fi

  if [[ -d "$mount_point" ]]; then
    dir_ok="y"
  else
    mkdir -p "$mount_point" && dir_ok="y" || dir_ok="n"
  fi
}

# Функция для монтирования устройства
mount_dir() {
  mount /dev/mapper/stegano_$loop_name "$mount_point"
  if [[ $? -eq 0 ]]; then
    if [[ -n "$SUDO_USER" ]]; then
      chown "$SUDO_USER:$SUDO_USER" "$mount_point"
    fi
    mount_ok="y"
  else
    echo "ERROR: Failed to mount the device."
    exit 1
  fi
}

# Функция для удаления маппинга
remove_map() {
  if [[ -b "/dev/mapper/stegano_$loop_name" ]]; then
    dmsetup remove stegano_$loop_name || {
      echo "ERROR: Can't remove mapped device."
      exit 1
    }
  fi
}

# Функция для проверки файловой системы
check_fs() {
  if blkid /dev/mapper/stegano_$loop_name >/dev/null 2>&1; then
    if ! e2fsck -n /dev/mapper/stegano_$loop_name >/dev/null 2>&1; then
      return
    fi
    fs_ok="y"
  fi
}

# Функция для создания файловой системы
create_fs() {
  if [[ $fs_ok != "y" ]]; then 
    echo "Usable size is $usable_size Mb."
    echo "No filesystem found, create new? (y/N)"
    read -r answer
    if [[ "$answer" == "y" ]]; then
      echo -n "Cleaning... "
      dd if=/dev/urandom of=/dev/mapper/stegano_$loop_name bs=512 count=$sectors status=none
      mkfs.ext4 -F -q /dev/mapper/stegano_$loop_name
      echo "done"
      if [[ $? -eq 0 ]]; then
        fs_ok="y"
      fi
    fi 
  fi
}

# Функция для маппинга файла
map_file() {
  enter_pass

  offset=0
  nsym=4
  while [[ $offset -lt 20000000 ]]; do
    sub=$(echo -n "$tmp" | head -c $nsym)
    offset=$((0x$sub))
    nsym=$((nsym + 1))
  done
    while [[ $offset -gt 60000000 ]]; do
    offset=$((offset / 2))
  done

  tailer=0
  nsym=4
  while [[ $tailer -lt 20000000 ]]; do
    sub=$(echo -n "$tmp" | tail -c $nsym)
    tailer=$((0x$sub))
    nsym=$((nsym + 1))
  done
  while [[ $tailer -gt 60000000 ]]; do
    tailer=$((tailer / 2))
  done

  filesize=$(stat --format="%s" "$input_file")

  usable_size=$(( (filesize - offset - tailer) / 1024 / 1024 ))
  if [[ $usable_size -lt 10 ]]; then
    echo "ERROR: Usable size too small! Select another file."
    exit 1
  fi

  sectors=$(( (filesize - offset - tailer) / 512 ))
  loop_device=$(losetup -f --show --offset $offset --size $((sectors * 512)) "$input_file")

  if [[ -n "$loop_device" ]]; then
    loop_name=$(basename "$loop_device")
    sectors=$(cat /sys/class/block/$loop_name/size)

    if [[ $sectors -gt 0 ]]; then
      echo "0 $sectors crypt $cipher $key 0 $loop_device 0" | dmsetup create stegano_$loop_name
      if [[ -b "/dev/mapper/stegano_$loop_name" ]]; then
        fs_ok="n"
        check_fs
        create_fs

        if [[ $fs_ok == "y" ]]; then
          dir_ok="n"
          check_dir

          if [[ "$dir_ok" == "y" ]]; then
            mount_ok="n"
            mount_dir
            if [[ "$mount_ok" == "y" ]]; then
              echo "Success: mounted at $mount_point"
              exit 0
            fi
          fi

          remove_map
          losetup -d "$loop_device"
          exit 0
        else
          unmap_file
        fi
      else
        echo "ERROR: Something went wrong while creating the mapped device."
        exit 1
      fi
    fi
  fi
}

# Функция для размонтирования устройства
unmap_file() {
  loop_name=$(basename "$loop_device")

  fs=$(mount | grep "/dev/mapper/stegano_$loop_name" | awk '{print $3}')
  if [[ -n "$fs" ]]; then
    umount "$fs" || {
      echo "ERROR: Still mounted as $fs"
      exit 1
    }
  fi

  remove_map
  losetup -d "$loop_device"
  echo "Device unmounted."
  exit 0
}

# Основной блок выполнения
file_ok="n"
check_file

if [[ $file_ok == "y" ]]; then
  is_mapped="n"
  check_map

  if [[ $is_mapped == "n" ]]; then
    map_file
  else
    unmap_file
  fi
fi

