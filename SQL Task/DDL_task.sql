CREATE TABLE rumah (
	nav_link_href TEXT PRIMARY KEY,
	listing_location VARCHAR(200),
	price VARCHAR(200),
	bed FLOAT,
	bath FLOAT,
	listing_floorarea VARCHAR(200),
	listing_floorarea2 VARCHAR(200)
);
--drop table rumah;

--Pada awalnya, primary key ingin menggunakan nav_link_href yang nilainya unik. 
--Namun karena datanya terlalu panjang, ketika diimport stringnya terpotong.
--Hal ini menyebabkan terdapat kemiripan key satu dengan yang lainnya karena terlalu pendek.
--Oleh karena itu, primary key menggunakan row number yang digabung dengan nav_link_href
