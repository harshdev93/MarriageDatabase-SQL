/*Author : Harshdev Singh Randhawa
	 ID  : 16200221 
*/


/*Table creation queries*/

CREATE DATABASE marriagedb;
use marriagedb;


CREATE TABLE marriage_rules_country(
country_id varchar(3) not null,
country_name varchar(40) not null,
male_age_limit int(3) not null,
female_age_limit int(3) not null,
age_limit_others int(3) not null,
polygamy_status boolean not null,
same_sex_marriage_status boolean not null,
PRIMARY KEY (country_id)
)ENGINE=INNODB;

CREATE TABLE marital_status(
marital_status_code int(2),
marital_status VARCHAR(15),
primary key(marital_status_code)
)ENGINE=INNODB;

CREATE TABLE religion(
religion_code int(2) NOT NULL,
religion_name VARCHAR(20),
primary key(religion_code)
)ENGINE=INNODB;

CREATE TABLE gender(
gender_code int(2) NOT NULL,
gender_name VARCHAR(20),
primary key(gender_code)
)ENGINE=INNODB;

CREATE TABLE salutations(
salutation_id int(2) NOT NULL,
salutation VARCHAR(10),
primary key(salutation_id)
)ENGINE=INNODB;

CREATE TABLE person(
unique_p_id int NOT NULL AUTO_INCREMENT, 
salutation_code int(2),
person_first_name VARCHAR(30) NOT NULL,
person_last_name VARCHAR(30),
date_of_birth DATE NOT NULL,
gender_code int(2),
nationality VARCHAR(50) NOT NULL,
passport_no VARCHAR(15) NOT NULL,
religion_code int(2),
marital_status_code int(2),
is_p_alive boolean default true,
current_no_marriage int(2) not null default 0,
PRIMARY KEY (unique_p_id),
UNIQUE KEY (passport_no,nationality),
foreign key (salutation_code) references salutations(salutation_id),
foreign key (gender_code) references gender(gender_code),
foreign key (religion_code) references religion(religion_code),
foreign key (marital_status_code) references marital_status(marital_status_code)
)ENGINE=INNODB;

CREATE TABLE address(
address_id int NOT NULL AUTO_INCREMENT, 
person_id int,
house_no varchar(15),
street_name Varchar(50),
city_name Varchar(15),
zip_code varchar(15),
PRIMARY KEY (address_id),
foreign key (person_id) references person(unique_p_id)
)ENGINE=INNODB;

CREATE TABLE marriage(
uniq_mrg_cert_no int NOT NULL AUTO_INCREMENT,
partner1_id int, 
partner2_id int,
place_of_marriage varchar(40) NOT NULL,
date_of_marriage date NOT NULL,
marriage_country_code varchar(3) NOT NULL,
PRIMARY KEY (uniq_mrg_cert_no),
foreign key (partner1_id) references person(unique_p_id),
foreign key (partner2_id) references person(unique_p_id),
foreign key (marriage_country_code) references marriage_rules_country(country_id)
)ENGINE=INNODB;

CREATE TABLE divorce(
divorce_decree_Number int NOT NULL AUTO_INCREMENT,
partner1_id int, 
partner2_id int,
marriage_end_date DATE NOT NULL,
uniq_mrg_cert_no int,
place_of_divorce varchar(40) NOT NULL,
divorce_country_code varchar(3) NOT NULL,
PRIMARY KEY (divorce_decree_Number),
foreign key (partner1_id) references person(unique_p_id),
foreign key (partner2_id) references person(unique_p_id),
foreign key (uniq_mrg_cert_no) references marriage(uniq_mrg_cert_no),
foreign key (divorce_country_code) references marriage_rules_country(country_id),
unique key(uniq_mrg_cert_no)
)ENGINE=INNODB;

CREATE TABLE death_records(
death_record_id int NOT NULL AUTO_INCREMENT,
unique_p_id int,
date_of_death date not null,
cause_of_death varchar(30),
PRIMARY KEY (death_record_id),
foreign key (unique_p_id) references person(unique_p_id),
unique key(unique_p_id)
)ENGINE=INNODB;

/*#################################################################################################################*/


/* Marriage Trigger before insert*/

delimiter //
CREATE TRIGGER marriage_BEFORE_INSERT BEFORE INSERT ON marriage FOR EACH ROW
BEGIN

/*Declaring variables*/
DECLARE marriageCount INT(2);
DECLARE divorceCount INT(2);
DECLARE maritalStatusCodeP1 INT(2);
DECLARE maritalStatusCodeP2 INT(2);
DECLARE p1_isAlive BOOLEAN;
DECLARE p2_isAlive BOOLEAN;
DECLARE dob_p1 DATE;
DECLARE dob_p2 DATE;
DECLARE polyStatus BOOLEAN;
DECLARE sameSexMrg BOOLEAN;
DECLARE curAgeP1 INT(3);
DECLARE curAgeP2 INT(3);
DECLARE maleAge INT(3);
DECLARE femaleAge INT(3);
DECLARE otherAge INT(3);
DECLARE p1Gender INT(2);
DECLARE p2Gender INT(2);

/*Get person details of first partner*/
SELECT is_p_alive,date_of_birth, gender_code, marital_status_code
INTO p1_isAlive, dob_p1, p1Gender, maritalStatusCodeP1
FROM person 
WHERE unique_p_id=NEW.partner1_id;

/*Get person details of second partner*/
SELECT is_p_alive,date_of_birth, gender_code, marital_status_code
INTO p2_isAlive, dob_p2, p2Gender, maritalStatusCodeP2
FROM person 
WHERE unique_p_id=NEW.partner2_id;

/*Get marriage rules from that particular country*/
SELECT polygamy_status, same_sex_marriage_status,male_age_limit,female_age_limit,age_limit_others
INTO polyStatus, sameSexMrg, maleAge, femaleAge, otherAge
FROM marriage_rules_country WHERE country_id=NEW.marriage_country_code;

/*Get the age of both the partners*/
SELECT round(DATEDIFF(CURDATE(),dob_p1)/365) INTO curAgeP1;
SELECT round(DATEDIFF(CURDATE(),dob_p2)/365) INTO curAgeP2;

/*No of marriage records for those partners*/
SELECT COUNT(*)
INTO  marriageCount
FROM marriage
where (partner1_id = new.partner1_id or partner1_id = new.partner2_id) and
(partner2_id = new.partner1_id or partner2_id = new.partner2_id);

/*No of divorce records for those partners*/
SELECT COUNT(*)
INTO  divorceCount
FROM divorce
where (partner1_id = new.partner1_id or partner1_id = new.partner2_id) and
(partner2_id = new.partner1_id or partner2_id = new.partner2_id);

/*Performing checks*/
IF (marriageCount > divorceCount)
THEN
SIGNAL SQLSTATE '46001'
SET MESSAGE_TEXT = "Already married to the same person";
END IF;

IF (!p1_isAlive OR !p2_isAlive)
THEN
SIGNAL SQLSTATE '46002'
SET MESSAGE_TEXT = "Partner is not alive";
END IF;

IF (new.partner1_id = new.partner2_id)
THEN
SIGNAL SQLSTATE '46003'
SET MESSAGE_TEXT = "Both partners cannot be same";
END IF;

IF ((maritalStatusCodeP1 = 1 OR maritalStatusCodeP2 = 1) and !polyStatus )
THEN
SIGNAL SQLSTATE '46004'
SET MESSAGE_TEXT = "polygamy_status is not allowed in selected country";
END IF;

IF (!sameSexMrg AND (p1Gender=p2Gender))
THEN
SIGNAL SQLSTATE '46005'
SET MESSAGE_TEXT = "Same sex marriage is not allowed in selected country";
END IF;

IF (((p1Gender=0 AND curAgeP1<maleAge) OR (p1Gender=0 AND curAgeP2<maleAge)) 
	OR ((p1Gender=1 AND curAgeP1<femaleAge) OR (p1Gender=1 AND curAgeP2<femaleAge))
    OR ((p1Gender=2 AND curAgeP1<otherAge) OR (p1Gender=2 AND curAgeP2<otherAge)))
THEN
SIGNAL SQLSTATE '46006'
SET MESSAGE_TEXT = "Persons age is less than the legal marriage age of the selected country";
END IF;

END;//
delimiter ;

/* marriage Trigger after insert*/

delimiter //
CREATE TRIGGER marriage_AFTER_INSERT AFTER INSERT ON marriage FOR EACH ROW
BEGIN

/*update the marital status to married and increase marriage count by 1*/
UPDATE person
SET marital_status_code=1,current_no_marriage=current_no_marriage + 1
WHERE unique_p_id=NEW.partner1_id
OR unique_p_id=NEW.partner2_id;

END;//
delimiter ;

/*#################################################################################################################*/

/* Divorce Trigegr before insert*/

delimiter //
CREATE TRIGGER divorce_BEFORE_INSERT BEFORE INSERT ON divorce FOR EACH ROW
BEGIN
DECLARE p1_isAlive boolean;
DECLARE p2_isAlive boolean;
DECLARE latest_uniq_mrg_cert_no boolean;
DECLARE mDate date;

/*Get is_alive info of partner 1*/
SELECT is_p_alive
INTO p1_isAlive 
FROM person 
WHERE unique_p_id=NEW.partner1_id;

/*Get is_alive info of partner 2*/
SELECT is_p_alive
INTO p2_isAlive 
FROM person 
WHERE unique_p_id=NEW.partner1_id;

/*Get the latest marriage record of the partners*/
SELECT MAX(uniq_mrg_cert_no) ,date_of_marriage
INTO latest_uniq_mrg_cert_no,mdate
FROM marriage
WHERE (partner1_id=NEW.partner1_id AND partner2_id=NEW.partner2_id)
OR (partner1_id=NEW.partner2_id AND partner2_id=NEW.partner1_id);

/*Condition checks*/
IF (!p1_isAlive OR !p2_isAlive)
THEN
SIGNAL SQLSTATE '47001'
SET MESSAGE_TEXT = "One of the Partners is Not Alive";
END IF;

IF (new.partner1_id = new.partner2_id)
THEN
SIGNAL SQLSTATE '47002'
SET MESSAGE_TEXT = "Partners Id can not be equal";
END IF;

IF (latest_uniq_mrg_cert_no <> NEW.uniq_mrg_cert_no)
THEN
SIGNAL SQLSTATE '47002'
SET MESSAGE_TEXT = "Marriage record not found";
END IF;

IF (mdate > NEW.marriage_end_date or CURDATE()<NEW.marriage_end_date)
THEN
SIGNAL SQLSTATE '47003'
SET MESSAGE_TEXT = "Invalid divorce date";
END IF;

END;//
delimiter ;

/* Divorce Trigegr after insert*/


delimiter //
CREATE TRIGGER divorce_AFTER_INSERT AFTER INSERT ON divorce FOR EACH ROW
BEGIN
/* This updates marital status to divorced and count of marriages is decreased by 1*/
UPDATE person
SET marital_status_code=3,current_no_marriage=current_no_marriage -1
WHERE unique_p_id=NEW.partner1_id
OR unique_p_id=NEW.partner2_id;

END;//
delimiter ;

/*#################################################################################################################*/


/* Death_records Trigegr before insert*/
delimiter //
CREATE TRIGGER death_records_BEFORE_INSERT BEFORE INSERT ON death_records FOR EACH ROW
BEGIN
DECLARE p1_isAlive boolean;

/*get the is_p_alive value in the variable*/
SELECT is_p_alive
INTO p1_isAlive 
FROM person 
WHERE unique_p_id=NEW.unique_p_id;


IF ( CURDATE()<NEW.date_of_death)
THEN
SIGNAL SQLSTATE '48001'
SET MESSAGE_TEXT = "invalid death date";
END IF;

IF (!p1_isAlive )
THEN
SIGNAL SQLSTATE '48002'
SET MESSAGE_TEXT = "The person is already dead";
END IF;
END;//
delimiter ;


/* Death_records Trigger after insert*/
delimiter //
CREATE TRIGGER death_records_AFTER_INSERT AFTER INSERT ON death_records FOR EACH ROW
BEGIN

/* select the marriage records of the person id who dont have corresponding divorce record and decrease the person marriage count by -1*/
update person
set current_no_marriage=current_no_marriage-1
where unique_p_id in (
select unique_p_id from (
select unique_p_id from person where unique_p_id in 
(select partner1_id from marriage where partner2_id=new.unique_p_id
union all
select partner2_id from marriage 
where partner1_id=new.unique_p_id)
and is_p_alive=true and marital_status_code=1
and unique_p_id not in (select partner1_id from divorce where partner2_id=new.unique_p_id
union all
select partner2_id from divorce where partner1_id=new.unique_p_id))
as t);
 
/* select the marriage records of the person id who dont have corresponding divorce record and set the person marital status to divorced*/
update person
set marital_status_code=2
where unique_p_id in (
select unique_p_id from (
select unique_p_id from person where unique_p_id in 
(select partner1_id from marriage where partner2_id=new.unique_p_id
union all
select partner2_id from marriage 
where partner1_id=new.unique_p_id)
and is_p_alive=true and marital_status_code=1
and unique_p_id not in (select partner1_id from divorce where partner2_id=new.unique_p_id
union all
select partner2_id from divorce where partner1_id=new.unique_p_id)and current_no_marriage=0)
 as t);

/* finally update the is_p_alive to false(DEAD) for that person*/
UPDATE person
SET is_p_alive=false
WHERE unique_p_id=NEW.unique_p_id;

END;//
delimiter ;

/*#################################################################################################################*/

