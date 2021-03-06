use Test::APIcast::Blackbox 'no_plan';

run_tests();

__DATA__

=== TEST 1: blacklist IPs but not the request IP
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "1.1.1.0/4", "2.2.2.2" ],
              "check_type": "blacklist"
            }
          },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /
--- response_body
GET / HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: blacklist the request IP
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "1.1.1.0/4", "127.0.0.1" ],
              "check_type": "blacklist"
            }
          },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /
--- response_body
IP address not allowed
--- error_code: 403
--- no_error_log
[error]

=== TEST 3: whitelist IPs but not the request IP
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "1.1.1.0/4", "2.2.2.2" ],
              "check_type": "whitelist"
            }
          },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /
--- response_body
IP address not allowed
--- error_code: 403
--- no_error_log
[error]

=== TEST 4: whitelist the request IP
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "1.1.1.0/4", "127.0.0.1" ],
              "check_type": "whitelist"
            }
          },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /
--- response_body
GET / HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: IP check policy denies and apicast accepts. IP check goes first in the chain
The request should be denied with the IP check policy error message.
--- configuration
{
  "services": [
    {
      "id": 42,
      "backend_version":  1,
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "127.0.0.1" ],
              "check_type": "blacklist"
            }
          },
          { "name": "apicast.policy.apicast" }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- request
GET /?user_key=uk
--- response_body
IP address not allowed
--- error_code: 403
--- no_error_log
[error]

=== TEST 6: both IP check and apicast deny. IP check goes first in the chain
The request should be denied with the IP check policy error message.
--- configuration
{
  "services": [
    {
      "id": 42,
      "backend_version":  1,
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "127.0.0.1" ],
              "check_type": "blacklist"
            }
          },
          { "name": "apicast.policy.apicast" }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authrep.xml {
    content_by_lua_block {
      ngx.exit(403)
    }
  }
--- request
GET /?user_key=uk
--- response_body
IP address not allowed
--- error_code: 403
--- no_error_log
[error]

=== TEST 7: apicast accepts and IP check denies. APIcast goes first in the chain
The request should be denied with the IP check policy error message.
--- configuration
{
  "services": [
    {
      "id": 42,
      "backend_version":  1,
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "policy_chain": [
          { "name": "apicast.policy.apicast" },
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "127.0.0.1" ],
              "check_type": "blacklist"
            }
          }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- request
GET /?user_key=uk
--- response_body
IP address not allowed
--- error_code: 403
--- no_error_log
[error]

=== TEST 8: both APIcast and IP check deny. APIcast goes first in the chain
The request should be denied with the APIcast error message.
--- configuration
{
  "services": [
    {
      "id": 42,
      "backend_version":  1,
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "policy_chain": [
          { "name": "apicast.policy.apicast" },
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "127.0.0.1" ],
              "check_type": "blacklist"
            }
          }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authrep.xml {
    content_by_lua_block {
      ngx.exit(403)
    }
  }
--- request
GET /?user_key=uk
--- response_body chomp
Authentication failed
--- error_code: 403
--- no_error_log
[error]

=== TEST 9: configure error message
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.ip_check",
            "configuration": {
              "ips": [ "127.0.0.1" ],
              "check_type": "blacklist",
              "error_msg": "A custom error message"
            }
          },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /
--- response_body
A custom error message
--- error_code: 403
--- no_error_log
[error]
