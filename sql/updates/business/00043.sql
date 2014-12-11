ALTER TABLE journal 
ADD COLUMN reverseid INT4 references journal(id) ON DELETE RESTRICT DEFAULT NULL;
