CREATE DATABASE ie3a_db;
USE ie3a_db;

CREATE TABLE products (
  sid varchar(255) NOT NULL,
  sname varchar(255) NOT NULL,
  scategory varchar(255) NOT NULL,
  sphoto varchar(255) NOT NULL,
  sprice int NOT NULL DEFAULT 0
);

INSERT INTO products VALUES
('c006','クリスマスプディング','ホール','cake01.jpg',2000),
('c0002','ブッシュド・ノエル','シートケーキ','cake02.jpg',250),
('c0003','イチゴとシブースドケーキ','ショートケーキ','cake03.jpg',400);