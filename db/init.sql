create table if not exists orders(
  id varchar(40) primary key,
  user_email text not null,
  amount numeric not null,
  status text not null default 'CREATED',
  created_at timestamptz default now()
);
