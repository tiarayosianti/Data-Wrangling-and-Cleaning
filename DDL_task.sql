CREATE TABLE rumah (
	prim_key INT PRIMARY KEY,
	nav_link_href VARCHAR(255),
	listing_location VARCHAR(200) NOT null,
	price VARCHAR(200),
	bed FLOAT,
	bath FLOAT,
	listing_floorarea VARCHAR(200),
	listing_floorarea2 VARCHAR(200)
);


--Pada awalnya, primary key ingin menggunakan nav_link_href yang nilainya unik. 
--Namun karena datanya terlalu panjang, ketika diimport stringnya terpotong.
--Hal ini menyebabkan terdapat kemiripan key satu dengan yang lainnya karena terlalu pendek.
--Oleh karena itu, primary key menggunakan row number
