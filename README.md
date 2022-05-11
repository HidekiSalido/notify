## docker
```
docker-compose up
```

## db
```
cd migrations
goose postgres "postgres://postgres:postgres@localhost:5438/postgres?connect_timeout=180&sslmode=disable" up
goose postgres "postgres://postgres:postgres@localhost:5438/postgres?connect_timeout=180&sslmode=disable" down
goose postgres "postgres://postgres:postgres@localhost:5438/postgres?connect_timeout=180&sslmode=disable" status

```
```
port 5438
```

## setup
```
go mod init hideki/notify
go mod tidy
```

## run
```
go run .
```
