DROP TABLE IF EXISTS raw_transactions;

CREATE TABLE raw_transactions (
    row_id        TEXT,
    ssn           TEXT,
    cc_num        TEXT,
    first_name    TEXT,
    last_name     TEXT,
    gender        TEXT,
    street        TEXT,
    city          TEXT,
    state         TEXT,
    zip           TEXT,
    lat           TEXT,
    long_         TEXT,
    city_pop      TEXT,
    job           TEXT,
    dob           TEXT,
    acct_num      TEXT,
    profile       TEXT,
    trans_num     TEXT,
    trans_date    TEXT,
    trans_time    TEXT,
    unix_time     TEXT,
    category      TEXT,
    amt           TEXT,
    is_fraud      TEXT,
    merchant      TEXT,
    merch_lat     TEXT,
    merch_long    TEXT,
    merchant_name TEXT
);

