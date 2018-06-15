#/bin/sh

curl -X POST -s \
--form-string "app_key=Hboz5OoSLTqqqGX4kdq7" \
--form-string "app_secret=6lXX25bsUyivcDqIvq7fbjdOiGYd8VIQSPqobWMW6aNXrLEAwLNLYnH7oik4RcQe" \
--form-string "target_type=channel" \
--form-string "target_alias=GOudcB" \
--form-string "content=$1" \
https://api.pushed.co/1/push
