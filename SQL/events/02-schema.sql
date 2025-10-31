\c swyw_events;
CREATE TABLE IF NOT EXISTS core.events_type (
    "id" SERIAL,
    "name" varchar(100) NOT NULL,
    "sort_order" integer NOT NULL,
    CONSTRAINT "pk_event_type_id" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS core.events (
    "id" SERIAL,
    "description" varchar(255) NOT NULL,
    "date" timestamp NOT NULL,
    "participants" varchar(255) NOT NULL,
    "remember" boolean NOT NULL,
    "type_event_id" integer NOT NULL,
    "user_id" integer NOT NULL,
    "title" text,
    "completed" boolean NOT NULL,
    CONSTRAINT "pk_Events_id" PRIMARY KEY ("id")
);


-- Foreign key constraints
-- Schema: core
ALTER TABLE core.events ADD CONSTRAINT "fk_type_event_id_event_type_id" FOREIGN KEY ("type_event_id") REFERENCES core.events_type ("id");
