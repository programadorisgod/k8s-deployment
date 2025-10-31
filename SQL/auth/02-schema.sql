\c swyw_auth;

CREATE TABLE IF NOT EXISTS core.users (
    id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    create_at TIMESTAMP DEFAULT NOW(),
    pass TEXT NOT NULL,
    CONSTRAINT pk_id_user PRIMARY KEY ("id")
);
