#!/bin/bash

# Cloudflare 区域ID,点击域名,进去后查看右下角
Cloudflare_ZONE_ID=此处填入区域ID

# Cloudflare 邮箱账号
Email=此处填入邮箱账号

# Cloudflare 账号全局 API KEY
Cloudflare_Global_API_KEY=此处填入全局 API KEY

# 二级域名
Record_Name_1=此处填入第 1 个需要绑定的二级域名

Record_Name_2=此处填入第 2 个需要绑定的二级域名

Record_Name_3=此处填入第 3 个需要绑定的二级域名

Record_Name_4=此处填入第 4 个需要绑定的二级域名

Record_Name_5=此处填入第 5 个需要绑定的二级域名

# 二级域名对应的 ID
Cloudflare_Name_ID_1=此处填入第 1 个二级域名通过 API 获取的 ID 值

Cloudflare_Name_ID_2=此处填入第 2 个二级域名通过 API 获取的 ID 值

Cloudflare_Name_ID_3=此处填入第 3 个二级域名通过 API 获取的 ID 值

Cloudflare_Name_ID_4=此处填入第 4 个二级域名通过 API 获取的 ID 值

Cloudflare_Name_ID_5=此处填入第 5 个二级域名通过 API 获取的 ID 值

# 初始化计数器
n=0

# 运行 CloudflareST -p 0 不输出到控制台
./cfst -p 0

# 读取 result.csv 并取每行的第一个字段（IPv4 地址）
while IFS=, read -r ip _  # IFS=, 设置分隔符为逗号，read -r ip 读取第一个字段（IPv4地址）
do
    n=$((n+1))

    if [ "$n" -eq 2 ]; then
        echo "$ip"
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$Cloudflare_ZONE_ID/dns_records/$Cloudflare_Name_ID_1" \
            -H "X-Auth-Email: $Email" \
            -H "X-Auth-Key: $Cloudflare_Global_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$Record_Name_1\",\"content\":\"$ip\",\"ttl\":60,\"proxied\":false}"
    fi

    if [ "$n" -eq 3 ]; then
        echo "$ip"
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$Cloudflare_ZONE_ID/dns_records/$Cloudflare_Name_ID_2" \
            -H "X-Auth-Email: $Email" \
            -H "X-Auth-Key: $Cloudflare_Global_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$Record_Name_2\",\"content\":\"$ip\",\"ttl\":60,\"proxied\":false}"
    fi

    if [ "$n" -eq 4 ]; then
        echo "$ip"
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$Cloudflare_ZONE_ID/dns_records/$Cloudflare_Name_ID_3" \
            -H "X-Auth-Email: $Email" \
            -H "X-Auth-Key: $Cloudflare_Global_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$Record_Name_3\",\"content\":\"$ip\",\"ttl\":60,\"proxied\":false}"
    fi

    if [ "$n" -eq 5 ]; then
        echo "$ip"
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$Cloudflare_ZONE_ID/dns_records/$Cloudflare_Name_ID_4" \
            -H "X-Auth-Email: $Email" \
            -H "X-Auth-Key: $Cloudflare_Global_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$Record_Name_4\",\"content\":\"$ip\",\"ttl\":60,\"proxied\":false}"
    fi

    if [ "$n" -eq 6 ]; then
        echo "$ip"
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$Cloudflare_ZONE_ID/dns_records/$Cloudflare_Name_ID_5" \
            -H "X-Auth-Email: $Email" \
            -H "X-Auth-Key: $Cloudflare_Global_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$Record_Name_5\",\"content\":\"$ip\",\"ttl\":60,\"proxied\":false}"
    fi
done < result.csv  # 从 result.csv 读取内容
