
library(httr)

## before this works, need to :
##
##   1) destroy 'vault' folder if it exists 
        #   (In order to reinitialize vault you will need to remove the 
        #   backend storage. How you do it depends on which backend you 
        #   are using. For instance, if it is the file backend, remove 
        #   the entire specified path; if it is consul, do a recursive 
        #   delete on the entire prefix. Alternately, point the path or 
        #   prefix to a different location.)
##
##   2) start a Vault server -- open terminal and type:
        #   cd vault-shiny-app
        #   vault server -config=api-test.hcl
##
##  [For 2) to work, you obvisouly need to have Vault downloaded and
##  installed. Follow instructions here:
##  https://www.vaultproject.io/intro/getting-started/install.html]


## initialize vault and save key(s) and the root token
r <- content(PUT('http://localhost:8200/v1/sys/init',
                 body = '{"secret_shares":1, "secret_threshold":1}',
                 encode = 'json'))

keys <- r$keys
root_token <- r$root_token

## unseal vault (only one key required in this demo example)
PUT('http://localhost:8200/v1/sys/unseal',
    body = paste0('{"key": "', keys[[1]], '"}'),
    encode = 'json')

## enable an authentication backend (ex: App-ID)
POST('http://127.0.0.1:8200/v1/sys/auth/app-id',
     add_headers(`X-Vault-Token` = root_token),
     body = '{"type":"app-id"}', 
     encode = 'json')

## associate the app with the root ACL policy ("foo" should be a UUID)
POST('http://localhost:8200/v1/auth/app-id/map/app-id/foo',
     add_headers(`X-Vault-Token` = root_token),
     body = '{"value":"root", "display_name":"demo"}', 
     encode = 'json')

## map app to user
POST('http://localhost:8200/v1/auth/app-id/map/user-id/bar',
     add_headers(`X-Vault-Token` = root_token),
     body = '{"value":"foo"}', 
     encode = 'json')

## authenticate:
## app can identify itself via the app-id and user-id and get access to Vault.
r <- content(POST('http://127.0.0.1:8200/v1/auth/app-id/login',
                  add_headers(`X-Vault-Token` = root_token),
                  body = '{"app_id":"foo", "user_id": "bar"}', 
                  encode = 'json'))

client_token <- r$auth$client_token

# ## use client_token to authenticate requests to Vault
# ## here, enter a secret for "key"
# POST('http://127.0.0.1:8200/v1/secret/test',
#      add_headers(`X-Vault-Token` = client_token,
#                  `Content-type` = "application/json"),
#      body = '{"key":"value"}',
#      encode = 'json')
# 
# ## read back the secret and check it's correct
# data <- content(GET('http://127.0.0.1:8200/v1/secret/test',
#                     add_headers(`X-Vault-Token` = client_token)))$data
# data$key == "value"


