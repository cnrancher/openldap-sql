drop database if exists `ldap`;
CREATE database `ldap` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
use ldap;

drop table if exists ldap_oc_mappings;
create table ldap_oc_mappings
(
  id integer unsigned not null primary key auto_increment,
  name varchar(64) not null,
  keytbl varchar(64) not null,
  keycol varchar(64) not null,
  create_proc varchar(255),
  delete_proc varchar(255),
  expect_return tinyint not null
);

drop table if exists ldap_attr_mappings;
create table ldap_attr_mappings
(
  id integer unsigned not null primary key auto_increment,
  oc_map_id integer unsigned not null references ldap_oc_mappings(id),
  name varchar(255) not null,
  sel_expr varchar(255) not null,
  sel_expr_u varchar(255),
  from_tbls varchar(255) not null,
  join_where varchar(255),
  add_proc varchar(255),
  delete_proc varchar(255),
  param_order tinyint not null,
  expect_return tinyint not null
);

drop table if exists ldap_entries;
create table ldap_entries
(
  id integer unsigned not null primary key auto_increment,
  dn varchar(255) not null,
  oc_map_id integer unsigned not null references ldap_oc_mappings(id),
  parent int NOT NULL ,
  keyval int NOT NULL 
);

drop table if exists ldap_entry_objclasses;
create table ldap_entry_objclasses
(
  entry_id integer not null references ldap_entries(id),
  oc_name varchar(64)
);

alter table ldap_entries add 
  constraint unq1_ldap_entries unique
  (
    oc_map_id,
    keyval
  );  

alter table ldap_entries add
  constraint unq2_ldap_entries unique
  (
    dn
  );  

drop table if exists persons;
CREATE TABLE persons (
  id int NOT NULL,
  name varchar(255) NOT NULL,
  surname varchar(255) NOT NULL,
  password varchar(64),
    employee_number varchar(255) NOT NULL DEFAULT '',
  uid varchar(255) NOT NULL DEFAULT '',
  state varchar(1) NOT NULL DEFAULT 0,
  url varchar(255) 
);

drop table if exists institutes;
CREATE TABLE institutes (
  id int NOT NULL,
  name varchar(255)
);

drop table if exists documents;
CREATE TABLE documents (
  id int NOT NULL,
  title varchar(255) NOT NULL,
  abstract varchar(255)
);

drop table if exists authors_docs;
CREATE TABLE authors_docs (
  pers_id int NOT NULL,
  doc_id int NOT NULL
);

drop table if exists phones;
CREATE TABLE phones (
  id int NOT NULL ,
  phone varchar(255) NOT NULL ,
  pers_id int NOT NULL 
);

drop table if exists certs;
CREATE TABLE certs (
  id int NOT NULL ,
  cert LONGBLOB NOT NULL,
  pers_id int NOT NULL 
);

drop table if exists groups;
CREATE TABLE groups (
  id int NOT NULL,
  name varchar(255) NOT NULL,
  PRIMARY KEY (id)
);

drop table if exists group_members;
CREATE TABLE group_members (
  group_id int NOT NULL,
  person_id int NOT NULL,
  UNIQUE KEY group_members_UN (group_id,person_id)
);

drop table if exists organizational_units;
CREATE TABLE organizational_units (
    id int NOT NULL,
    name varchar(255) NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE authors_docs  ADD 
  CONSTRAINT PK_authors_docs PRIMARY KEY  
  (
    pers_id,
    doc_id
  );

ALTER TABLE documents  ADD 
  CONSTRAINT PK_documents PRIMARY KEY  
  (
    id
  ); 

ALTER TABLE institutes  ADD 
  CONSTRAINT PK_institutes PRIMARY KEY  
  (
    id
  );  


ALTER TABLE persons  ADD 
  CONSTRAINT PK_persons PRIMARY KEY  
  (
    id
  ); 

ALTER TABLE phones  ADD 
  CONSTRAINT PK_phones PRIMARY KEY  
  (
    id
  ); 

ALTER TABLE certs  ADD 
  CONSTRAINT PK_certs PRIMARY KEY  
  (
    id
  ); 

drop table if exists referrals;
CREATE TABLE referrals (
  id int NOT NULL,
  name varchar(255) NOT NULL,
  url varchar(255) NOT NULL
);

-- mappings 

-- objectClass mappings: these may be viewed as structuralObjectClass, the ones that are used to decide how to build an entry
--	id		a unique number identifying the objectClass
--	name		the name of the objectClass; it MUST match the name of an objectClass that is loaded in slapd's schema
--	keytbl		the name of the table that is referenced for the primary key of an entry
--	keycol		the name of the column in "keytbl" that contains the primary key of an entry; the pair "keytbl.keycol" uniquely identifies an entry of objectClass "id"
--	create_proc	a procedure to create the entry
--	delete_proc	a procedure to delete the entry; it takes "keytbl.keycol" of the row to be deleted
--	expect_return	a bitmap that marks whether create_proc (1) and delete_proc (2) return a value or not
insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (1,'inetOrgPerson','persons','id','SELECT create_person()','DELETE FROM persons WHERE id=?',0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (2,'document','documents','id','SELECT create_doc()','DELETE FROM documents WHERE id=?',0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (3,'organization','institutes','id','SELECT create_o()','DELETE FROM institutes WHERE id=?',0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (4,'referral','referrals','id','SELECT create_referral()','DELETE FROM referrals WHERE id=?',0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (5,'groupOfNames','groups','id','SELECT create_group()','DELETE FROM groups WHERE id=?',0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (6,'organizationalUnit','organizational_units','id','SELECT create_organizational_unit()','DELETE FROM organizational_units WHERE id=?',0);

-- attributeType mappings: describe how an attributeType for a certain objectClass maps to the SQL data.
--	id		a unique number identifying the attribute	
--	oc_map_id	the value of "ldap_oc_mappings.id" that identifies the objectClass this attributeType is defined for
--	name		the name of the attributeType; it MUST match the name of an attributeType that is loaded in slapd's schema
--	sel_expr	the expression that is used to select this attribute (the "select <sel_expr> from ..." portion)
--	from_tbls	the expression that defines the table(s) this attribute is taken from (the "select ... from <from_tbls> where ..." portion)
--	join_where	the expression that defines the condition to select this attribute (the "select ... where <join_where> ..." portion)
--	add_proc	a procedure to insert the attribute; it takes the value of the attribute that is added, and the "keytbl.keycol" of the entry it is associated to
--	delete_proc	a procedure to delete the attribute; it takes the value of the attribute that is added, and the "keytbl.keycol" of the entry it is associated to
--	param_order	a mask that marks if the "keytbl.keycol" value comes before or after the value in add_proc (1) and delete_proc (2)
--	expect_return	a mask that marks whether add_proc (1) and delete_proc(2) are expected to return a value or not
insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (1,1,'cn',"persons.uid",'persons',NULL,'Update persons SET uid=? WHERE id=?','Update persons SET uid='''' WHERE (uid=? OR uid='''') AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (2,1,'telephoneNumber','phones.phone','persons,phones',
        'phones.pers_id=persons.id','SELECT add_phone(?,?)','DELETE FROM phones WHERE phone=? AND pers_id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (3,1,'givenName','persons.name','persons',NULL,'UPDATE persons SET name=? WHERE id=?','UPDATE persons SET name='''' WHERE (name=? OR name='''') AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (4,1,'sn','persons.surname','persons',NULL,'UPDATE persons SET surname=? WHERE id=?','UPDATE persons SET surname='''' WHERE (surname=? OR surname='''') AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (5,1,'userPassword','persons.password','persons','persons.password IS NOT NULL','UPDATE persons SET password=? WHERE id=?','UPDATE persons SET password=NULL WHERE password=? AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (6,1,'seeAlso','seeAlso.dn','ldap_entries AS seeAlso,documents,authors_docs,persons',
        'seeAlso.keyval=documents.id AND seeAlso.oc_map_id=2 AND authors_docs.doc_id=documents.id AND authors_docs.pers_id=persons.id',
      NULL,
        'DELETE from authors_docs WHERE authors_docs.doc_id=(SELECT documents.id FROM documents,ldap_entries AS seeAlso WHERE seeAlso.keyval=documents.id AND seeAlso.oc_map_id=2 AND seeAlso.dn=?) AND authors_docs.pers_id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (7,2,'description','documents.abstract','documents',NULL,
        'UPDATE documents SET abstract=? WHERE id=?',
        'UPDATE documents SET abstract='''' WHERE abstract=? AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (8,2,'documentTitle','documents.title','documents',NULL,
        'UPDATE documents SET title=? WHERE id=?',
        'UPDATE documents SET title='''' WHERE title=? AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (9,2,'documentAuthor','documentAuthor.dn','ldap_entries AS documentAuthor,documents,authors_docs,persons',
  'documentAuthor.keyval=persons.id AND documentAuthor.oc_map_id=1 AND authors_docs.doc_id=documents.id AND authors_docs.pers_id=persons.id',
  'INSERT INTO authors_docs (pers_id,doc_id) VALUES ((SELECT ldap_entries.keyval FROM ldap_entries WHERE upper(?)=upper(ldap_entries.dn)),?)',
    'DELETE FROM authors_docs WHERE authors_docs.pers_id=(SELECT ldap_entries.keyval FROM ldap_entries WHERE upper(?)=upper(ldap_entries.dn)) AND authors_docs.doc_id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (10,2,'documentIdentifier','concat(''document '',documents.id)','documents',NULL,NULL,
        'SELECT 1 FROM documents WHERE title=? AND id=? AND 1=0',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (11,3,'o','institutes.name','institutes',NULL,
        'UPDATE institutes SET name=? WHERE id=?',
        'UPDATE institutes SET name='''' WHERE name=? AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (12,3,'dc','lower(institutes.name)','institutes,ldap_entries AS dcObject,ldap_entry_objclasses as auxObjectClass',
  'institutes.id=dcObject.keyval AND dcObject.oc_map_id=3 AND dcObject.id=auxObjectClass.entry_id AND auxObjectClass.oc_name=''dcObject''',
  NULL,
    'SELECT 1 FROM institutes WHERE lower(name)=? AND id=? and 1=0',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (13,4,'ou','referrals.name','referrals',NULL,
        'UPDATE referrals SET name=? WHERE id=?',
        'SELECT 1 FROM referrals WHERE name=? AND id=? and 1=0',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (14,4,'ref','referrals.url','referrals',NULL,
        'UPDATE referrals SET url=? WHERE id=?',
        'SELECT 1 FROM referrals WHERE url=? and id=? and 1=0',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (15,1,'userCertificate','certs.cert','persons,certs',
        'certs.pers_id=persons.id',NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return) 
values (16,1,'employeeNumber','persons.employee_number','persons',NULL,
        'UPDATE persons SET employee_number=? WHERE id=?','UPDATE persons SET employee_number='''' WHERE (employee_number=? OR employee_number='''') AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return) 
values (17,1,'uid','persons.uid','persons',NULL,'Update persons SET uid=? WHERE id=?','Update persons SET uid='''' WHERE (uid=? OR uid='''') AND id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (18,1,'postalCode','persons.state','persons',NULL,'Update persons set state=? where id=?','Update persons SET state='''' where (state=? or state='''') and id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (19,1,'ref','persons.url','persons',NULL,'Update persons set url=? where id=?','Update persons set url='''' where (url=? or url='''') and id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (20,1,'displayName','concat(persons.name,'' '',persons.surname)','persons',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (21,5,'ou','groups.name','groups',NULL,'Update groups set name=? where id=?','update groups set name='''' where (name=? or name='''') and id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (22,5,'cn','groups.name','groups',NULL,'Update groups set name=? where id=?','update groups set name='''' where (name=? or name='''') and id=?',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (23,5,'member','persons_entries.dn','ldap_entries AS persons_entries,groups,group_members','group_members.person_id=persons_entries.keyval AND persons_entries.oc_map_id=1 AND group_members.group_id=groups.id','SELECT add_member(?,?)','SELECT delete_member(?,?)',3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (24,6,'ou','organizational_units.name','organizational_units',NULL,'Update organizational_units set name=? where id=?','update organizational_units set name='''' where (name=? or name='''') and id=?',3,0);

-- entries mapping: each entry must appear in this table, with a unique DN rooted at the database naming context
--	id		a unique number > 0 identifying the entry
--	dn		the DN of the entry, in "pretty" form
--	oc_map_id	the "ldap_oc_mappings.id" of the main objectClass of this entry (view it as the structuralObjectClass)
--	parent		the "ldap_entries.id" of the parent of this objectClass; 0 if it is the "suffix" of the database
--	keyval		the value of the "keytbl.keycol" defined for this objectClass
insert into ldap_entries (id,dn,oc_map_id,parent,keyval)
values (1,'dc=example,dc=com',3,0,1);

insert into ldap_entries
(id, dn, oc_map_id, parent, keyval)
values(2, 'ou=accounts,dc=example,dc=com', 6, 1, 1);

insert into ldap_entries
(id, dn, oc_map_id, parent, keyval)
values(3, 'ou=groups,dc=example,dc=com', 6, 1, 2);

-- objectClass mapping: entries that have multiple objectClass instances are listed here with the objectClass name (view them as auxiliary objectClass)
--	entry_id	the "ldap_entries.id" of the entry this objectClass value must be added
--	oc_name		the name of the objectClass; it MUST match the name of an objectClass that is loaded in slapd's schema
insert into ldap_entry_objclasses (entry_id,oc_name)
values (1,'dcObject');

insert into ldap_entry_objclasses (entry_id,oc_name)
values (2,'top');

insert into ldap_entry_objclasses (entry_id,oc_name)
values (3,'top');

insert into institutes (id,name) values (1,'Example');

insert into referrals (id,name,url) values (1,'Referral','ldap://localhost:9012/');

insert into organizational_units (id, name)
values(1, 'accounts');

insert into organizational_units (id, name)
values(2, 'groups');
-- procedures
-- these procedures are specific for this RDBMS and are used in mapping objectClass and attributeType creation/modify/deletion
delimiter //
create function create_person () returns int
begin
  set @persons_id_seq = (select coalesce(max(id), 0) from persons);
  insert into persons (id,name,surname) 
    values ((@persons_id_seq + 1),'''','''');
  return (select max(id) from persons);
end //
delimiter ;

delimiter //
create function add_phone (phone varchar(255), pers_id int) returns int
begin
    set @phones_id_seq = (select coalesce(max(id), 0) from phones);
  insert into phones (id,phone, pers_id)
    values ((@phones_id_seq + 1), phone, pers_id);
  return (select max(id) from phones);
end //
delimiter ;

delimiter //
create function create_doc () returns int
begin
    set @documents_id_seq = (select coalesce(max(id), 0) from documents);
  insert into documents (id,title,abstract) 
    values ((@documents_id_seq + 1),'''','''');
  return (select max(id) from documents);
end //
delimiter ;

delimiter //
create function create_o () returns int
begin
    set @institutes_id_seq = (select coalesce(max(id), 0) from institutes);
  insert into institutes (id,name) 
    values ((@institutes_id_seq + 1),'''');
  return (select max(id) from institutes);
end //
delimiter ;

delimiter //
create function create_referral () returns int
begin
    set @referrals_id_seq = (select coalesce(max(id), 0) from referrals);
  insert into referrals (id,name,url) 
    values ((@referrals_id_seq + 1),'''','''');
  return (select max(id) from referrals);
end //
delimiter ;

delimiter //
create function create_organizational_unit () returns int
begin
    set @organizational_unit_id_seq = (select coalesce(max(id), 0) from organizational_units);
  insert into organizational_units (id,name) 
    values ((@organizational_unit_id_seq + 1),'''');
  return (select max(id) from organizational_units);
end //
delimiter ;

delimiter //
create function create_group () returns int
begin
    set @group_id_seq = (select coalesce(max(id), 0) from groups);
  insert into groups (id,name) 
    values ((@group_id_seq + 1),'''');
  return (select max(id) from groups);
end //
delimiter ;

delimiter //
create function add_member (person_dn varchar(255), gid int) returns int
begin
  set @person_id = (select keyval from ldap_entries where dn=person_dn AND oc_map_id=1);
  set @exist = (select count(*) from group_members where group_id=gid AND person_id=@person_id);
  if @exist>0 then
      return 1;
  else
    insert into group_members (person_id, group_id) values (@person_id,gid);
      return 0;
  end if;
end //
delimiter ;

delimiter //
create function delete_member (person_dn varchar(255), group_id int) returns int
begin
    set @person_id = (select keyval from ldap_entries where dn=person_dn AND oc_map_id=1);
  delete from group_members where group_members.person_id=@person_id AND group_members.group_id=group_id;
  return 0;
end //
delimiter ;