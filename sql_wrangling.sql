-- STRUCTURING
-- rename kolom
select
	nav_link_href as link_href,
	listing_location,
	price,
	bed,
	bath,
	listing_floorarea as house_area,
	listing_floorarea2 as price_area
from rumah;

with 
home as (
	select
		nav_link_href as link_href,
		listing_location,
		price,
		bed,
		bath,
		listing_floorarea as house_area,
		listing_floorarea2 as price_area
	from rumah
), 
home2 as ( 
-- CLEANING   select distinct --remove duplicate
		link_href,
		listing_location,
		bed,
		bath,
		CAST(REPLACE(SUBSTRING(house_area FROM '(\d+(?:[.,]\d+)?)'),  -- ambil angka sebelum 'm'
           ',', '.') AS VARCHAR(200)
           ) as luas_rumah,
		CAST(
	       REPLACE(REGEXP_REPLACE(price_area, 'Rp\s*|\s*per\s*m²', '', 'g'),'.', '') as VARCHAR(200)
	       ) AS harga_per_m2,
	  	CAST(                                   -- ubah string -> angka
	       REPLACE(                              -- koma -> titik
	          (REGEXP_MATCH(price, '^\s*([0-9]+(?:[.,][0-9]+)?)'))[1],',', '.') AS NUMERIC) *
	       CASE                                    -- faktor kali
	          WHEN REGEXP_REPLACE(price, '[^A-Za-z]', '', 'g') ILIKE 'M%'  THEN 1000000000   -- Milyar
	          ELSE 1000000                          -- Juta
	       end as harga_bangunan
	from home
),
home3 as ( -- handle outlier
	select
	    link_href,
		listing_location,
		LEAST(bed, 1) as jumlah_kamar,
		LEAST(bath, 1) as jumlah_km,
		cast((nullif(trim(luas_rumah), '')) as float) as luas_rumah,
		cast((nullif(trim(harga_per_m2), '')) as float) as harga_per_m2,
		harga_bangunan
     from home2 
),
home4 as ( -- handling putlier and missing values
	select
	    link_href,
		listing_location,	
		jumlah_kamar,
		jumlah_km,
        LEAST(GREATEST(COALESCE(luas_rumah::numeric,
            ROUND(AVG(luas_rumah) OVER (PARTITION BY listing_location)::numeric, 2))
            , 28.8::numeric), 10000::numeric) as luas_rumah,
        LEAST(GREATEST(COALESCE(harga_per_m2::numeric,
            ROUND(AVG(harga_per_m2) OVER (PARTITION BY listing_location)::numeric,2))
            , 950000::numeric), 75000000::numeric) as harga_per_m2,
        LEAST(GREATEST(COALESCE(harga_bangunan::numeric,
            ROUND(AVG(harga_bangunan) OVER (PARTITION BY listing_location)::numeric, 2))
            , 100000000::numeric), 5000000000::numeric) as harga_bangunan
    from home3
), 
-- enriching
kel_list(kel) AS (          -- daftar kelurahan (boleh ditambah kapan saja)
  VALUES
    ('Cipayung'),  ('Ciputat'),      ('Jombang'),      ('Sawah Baru'),
    ('Sawah Lama'), ('Serua'),       ('Serua Indah'),
    ('Cempaka Putih'), ('Cireundeu'), ('Pisangan'),        ('Pondok Ranji'),
    ('Rempoa'),     ('Rengas'),
    ('Bambu Apus'), ('Benda Baru'),  ('Kedaung'),
    ('Pamulang Barat'), ('Pamulang Timur'),
    ('Pondok Benda'), ('Pondok Cabe Ilir'), ('Pondok Cabe Udik'),
    ('Jurangmangu Barat'), ('Jurangmangu Timur'),
    ('Pondok Kacang Barat'), ('Pondok Kacang Timur'),
    ('Perigi Lama'), ('Perigi Baru'), ('Pondok Aren'),  ('Pondok Karya'),
    ('Pondok Jaya'), ('Pondok Betung'), ('Pondok Pucung'),
    ('Buaran'), ('Ciater'), ('Cilenggang'),
    ('Lengkong Gudang'), ('Lengkong Gudang Timur'), ('Lengkong Wetan'),
    ('Rawa Buntu'), ('Rawa Mekar Jaya'), ('Serpong'),
    ('Jelupang'), ('Lengkong Karya'), ('Pakualam'),
    ('Pakulonan'), ('Paku Jaya'),
    ('Pondok Jagung'), ('Pondok Jagung Timur'),
    ('Babakan'), ('Bakti Jaya'), ('Kademangan'), ('Keranggan'),
    ('Muncul'), ('Setu')
),
home5 as ( 
	select
	    link_href,
		listing_location,	
		jumlah_kamar,
		jumlah_km,
		luas_rumah,
		harga_per_m2,
		harga_bangunan,
		CASE
		    WHEN listing_location ILIKE '%Ciputat Timur%' THEN 'Ciputat Timur'
		    WHEN listing_location ILIKE '%Ciputat%'       THEN 'Ciputat'
		    WHEN listing_location ILIKE '%Pamulang%'      THEN 'Pamulang'
		    WHEN listing_location ILIKE '%Pondok Aren%'   THEN 'Pondok Aren'
		    WHEN listing_location ILIKE '%Serpong Utara%' THEN 'Serpong Utara'
		    WHEN listing_location ILIKE '%Serpong%'       THEN 'Serpong'
		    WHEN listing_location ILIKE '%Setu%'          THEN 'Setu'
		    ELSE 'lainnya'
		END AS kecamatan,
		COALESCE(
		    (
		      SELECT k.kel
		      FROM   kel_list k
		      WHERE  lower(h.listing_location) LIKE '%' || lower(k.kel) || '%'
		      ORDER  BY char_length(k.kel) DESC   -- pilih yang paling spesifik
		      LIMIT  1
		    ),
		    'lainnya'
		  ) AS kelurahan
	from home4 h
)
select * from home5 order by link_href; 


