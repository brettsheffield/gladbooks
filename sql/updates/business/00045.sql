CREATE TABLE salesorderitem (
        id              SERIAL PRIMARY KEY,
        uuid            uuid,
        updated         timestamp with time zone default now(),
        authuser        TEXT,
        clientip        TEXT
);
