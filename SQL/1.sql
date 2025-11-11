-- 1) База
CREATE DATABASE IF NOT EXISTS wod13
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 2) Пользователь только с локальной машины
CREATE USER 'ss13'@'127.0.0.1' IDENTIFIED BY 'Undead2005';

-- 3) Права на эту базу (хватает для большинства форков /tg/)
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, ALTER
ON wod13.* TO 'ss13'@'127.0.0.1';

FLUSH PRIVILEGES;