# **Hidden encrypted volume**

### Overview
This program allows you to create and mount encrypted volumes, hiding them inside regular large files.
For example, you can hide an encrypted volume inside a copy of movie (*.avi), DVD-image (*.iso), large archive file, etc.
Of course, the original file will be damaged, but will partially retain its propertied, i.e. it will be recognized as movie, DVD-image and archive file.
This will make it difficult to detect and attempt to decipher.

The program uses the standard Linux utilities.

### Installation
To install just copy script to PATH
```sh
sudo cp stegodisk /usr/.../bin/
```

### Usage

Create and mount:
```sh
stegodisk file-container [ mountpoint ]
```

![](https://raw.githubusercontent.com/unton3ton/stegodisk/refs/heads/main/mount.PNG)


Unmount:
```sh
stegodisk file-container
```

![](https://raw.githubusercontent.com/unton3ton/stegodisk/refs/heads/main/unmount.PNG)

The program will ask for the volume password. If the volume inside the container has already been created with the same password, 
it will be opened and mounted.
If the disk with such a password is not found, the program will offer to create it, and the insides of the container file will be 
overwritten, and the old data will be destroyed.
There is no way to recover a forgotten password.

Please do not use the program for illegal activities.

### Ciphers
    AES (aes-cbc-plain64, aes-xts-plain64, aes-lrw-plain64)
    Serpent (serpent-xts-plain64, serpent-cbc-plain64)
    Twofish (twofish-xts-plain64, twofish-cbc-plain64)
    Camellia (camellia-xts-plain64, camellia-cbc-plain64)

![](https://raw.githubusercontent.com/unton3ton/stegodisk/refs/heads/main/serpent.png)

```bash
sudo chmod 777 stegodisk2version.sh  
sudo ./stegodisk2version.sh Snatch.mp4 ./stegotest2
```

## How it works?

Этот Bash-скрипт предназначен для работы с зашифрованными файлами, используя механизм маппинга устройств в Linux. Он позволяет 
монтировать и размонтировать зашифрованные файловые системы, используя шифрование с помощью алгоритма Serpent в режиме XTS. 
Давайте разберем его по частям.

### Основные части скрипта

1. **Проверка прав пользователя**:
   ```bash
   if [ $EUID -ne 0 ] ; then
     exec sudo "$0" "$@"
   fi
   ```
   Скрипт проверяет, запущен ли он от имени суперпользователя (root). Если нет, он перезапускает себя с `sudo`.

2. **Параметры**:
   ```bash
   file=$1
   dir=$2
   ```
   Скрипт принимает два аргумента: путь к файлу и точку монтирования.

3. **Функции**:
   - `check_file`: Проверяет, существует ли указанный файл.
   - `check_map`: Проверяет, смонтирован ли файл как устройство.
   - `enter_pass`: Запрашивает у пользователя пароль и генерирует ключ для шифрования.
   - `check_dir`: Проверяет, существует ли указанная директория, и создает ее, если она не существует.
   - `mount_dir`: Монтирует зашифрованное устройство в указанную директорию.
   - `remove_map`: Удаляет маппинг устройства.
   - `check_fs`: Проверяет, существует ли файловая система на смонтированном устройстве.
   - `create_fs`: Создает новую файловую систему, если она не найдена.
   - `map_file`: Основная функция, которая обрабатывает маппинг файла и монтирование.
   - `unmap_file`: Размонтирует устройство и удаляет маппинг.

4. **Логика работы**:
   - Скрипт сначала проверяет, существует ли файл и маппинг.
   - Если файл не смонтирован, он запрашивает пароль, генерирует ключ и маппит файл.
   - Если файл уже смонтирован, он размонтирует его.

### Примечания по коду

- **Шифрование**: Используется алгоритм `serpent-xts-plain64` для шифрования данных.
- **Проверка файловой системы**: Используется `e2fsck` для проверки целостности файловой системы.
- **Создание файловой системы**: Если файловая система не найдена, скрипт предлагает создать новую.
- **Обработка ошибок**: Скрипт содержит проверки на ошибки, например, при монтировании и размонтировании.

### Заключение

Этот скрипт является мощным инструментом для работы с зашифрованными файлами в Linux, позволяя пользователю легко монтировать 
и размонтировать зашифрованные файловые системы. Он требует прав суперпользователя для выполнения операций, связанных с 
маппингом устройств и монтированием.


В контексте данного скрипта под "маппингом" (или "маппингом устройства") понимается процесс создания виртуального устройства, 
которое ссылается на физический файл или раздел диска. Это позволяет работать с файлом как с блочным устройством, что удобно 
для работы с файловыми системами и шифрованием.

### Как это работает

1. **Создание виртуального устройства**: 
   - Скрипт использует команду `losetup`, чтобы создать виртуальное блочное устройство, которое ссылается на указанный файл. Это устройство может быть использовано для монтирования файловой системы, находящейся внутри файла.
   - Например, если у вас есть файл, который содержит зашифрованную файловую систему, вы можете создать маппинг этого файла, чтобы операционная система воспринимала его как обычное блочное устройство.

2. **Использование `dmsetup`**:
   - Скрипт также использует `dmsetup` для создания маппинга с использованием шифрования. Это позволяет зашифровать данные, которые будут записываться на виртуальное устройство, и расшифровать их при чтении.

3. **Монтирование**:
   - После создания маппинга, скрипт может монтировать это виртуальное устройство в указанную директорию, что позволяет пользователю взаимодействовать с файловой системой, находящейся внутри файла, как если бы это был обычный раздел диска.

4. **Размонтирование и удаление маппинга**:
   - Когда работа с файловой системой завершена, скрипт размонтирует устройство и удаляет маппинг, освобождая ресурсы.

### Преимущества маппинга

- **Безопасность**: Позволяет работать с зашифрованными данными, не раскрывая их содержимое.
- **Гибкость**: Можно использовать файлы как блочные устройства, что упрощает управление данными.
- **Удобство**: Позволяет монтировать и размонтировать зашифрованные файловые системы по мере необходимости.

Таким образом, маппинг в данном контексте — это способ создания виртуального представления файла или раздела, позволяющий 
работать с ним как с блочным устройством.


# Sources

* [Прячем шифрованные диски](https://habr.com/ru/articles/896236/)
* [Serpent (с латыни — «змея»)](https://ru.wikipedia.org/wiki/Serpent)


![](https://raw.githubusercontent.com/unton3ton/stegodisk/refs/heads/main/67780d1324f61824128fd926.png)
