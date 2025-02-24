### Pre requisites
- PostgresSQL
- Ruby > 3.0.0
- iconv

### Overview
This CLI app follows 4 steps to get the database running:

- Download all files from a specific version.
- Unzip those files.
- Fix malformed strings, strange characteres and other encoding issues using `sed` and `iconv`.
- Import those files to the Postgres database.

### Usage

After cloning this repo the only configuration needed is your database URL connection, so open the `src/config/database.yml`
and put your URL there.
Then navigate to project's root folder and run `ruby main.rb` and follow the instructions.

### Screenshots

#### Select version
![image](https://github.com/user-attachments/assets/a31371a7-6fb7-4e4e-a9c6-6d7fd1b818fd)

#### Confirm download
![image](https://github.com/user-attachments/assets/f04ea8bf-a63e-4301-9173-f8937ff67b78)

#### Download Status
![image](https://github.com/user-attachments/assets/cc477b40-396e-4bd8-8f01-16f285208fb2)

### Fixing files and import
![image](https://github.com/user-attachments/assets/db95e85b-69df-482d-8d11-3b411ecd6ca7)


#### Database ready to use
![image](https://github.com/user-attachments/assets/9fcb9eda-b323-4fa3-8446-bc78dcffe3d6)
