CREATE TABLE tasks(
    id INTEGER UNIQUE,
    servstatus INTEGER,
    dobefore DATETIME,
    pps_terminal_id INTEGER,
    terminal_break_name TEXT,
    route_priority INTEGER,
    info TEXT,
    mark_latitude DECIMAL,
    mark_longitude DECIMAL,
    executionmark_ts DATETIME,
    inv_num TEXT,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0,

    is_seen INTEGER DEFAULT 0
);
CREATE TABLE terminals(
    id INTEGER UNIQUE,
    code TEXT,
    address TEXT,
    lastactivitytime DATETIME,
    lastpaymenttime DATETIME,
    errortext TEXT,
    src_system_name TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    mobileop TEXT,
    terminalId INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE components(
    id INTEGER UNIQUE,
    name TEXT,
    serial TEXT,
    component_group_id INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE component_groups(
    id INTEGER UNIQUE,
    name TEXT,
    is_manual_replacement INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE repairs(
    id INTEGER UNIQUE,
    name TEXT,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE defects(
    id INTEGER UNIQUE,
    name TEXT,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE task_defect_link(
    task_id INTEGER,
    defect_id INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE task_repair_link(
    task_id INTEGER,
    repair_id INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE terminal_component_link(
    task_id INTEGER,
    comp_id INTEGER,
    component_group_id INTEGER,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
CREATE TABLE locations(
    latitude  DECIMAL(18,10),
    longitude DECIMAL(18,10),
    accuracy  DECIMAL(18,10),
    altitude  DECIMAL(18,10),
    ts        DATETIME DEFAULT CURRENT_TIMESTAMP,

    local_ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    local_id INTEGER PRIMARY KEY,
    local_inserted INTEGER DEFAULT 0,
    local_updated INTEGER DEFAULT 0,
    local_deleted INTEGER DEFAULT 0
);
