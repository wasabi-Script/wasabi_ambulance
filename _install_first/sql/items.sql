DELETE FROM items WHERE name = 'burncream';
DELETE FROM items WHERE name = 'defib';
DELETE FROM items WHERE name = 'icepack';
DELETE FROM items WHERE name = 'medbag';
DELETE FROM items WHERE name = 'medikit';
DELETE FROM items WHERE name = 'sedative';
DELETE FROM items WHERE name = 'suturekit';
DELETE FROM items WHERE name = 'tweezers';


INSERT INTO `items` (`name`, `label`, `weight`) VALUES
	('burncream', 'Burn Cream', 1),
	('defib', 'Defibrillator', 1),
	('icepack', 'Ice Pack', 1),
	('medbag', 'Medical Bag', 1),
	('medikit', 'Medkit', 1),
	('sedative', 'Sedative', 1),
	('suturekit', 'Suture Kit', 1),
	('tweezers', 'Tweezers', 1)
;