**Hidden encrypted volume**

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

Unmount:
```sh
stegodisk file-container
```

The program will ask for the volume password. If the volume inside the container has already been created with the same password, 
it will be opened and mounted.
If the disk with such a password is not found, the program will offer to create it, and the insides of the container file will be 
overwritten, and the old data will be destroyed.
There is no way to recover a forgotten password.

Please do not use the program for illegal activities.


