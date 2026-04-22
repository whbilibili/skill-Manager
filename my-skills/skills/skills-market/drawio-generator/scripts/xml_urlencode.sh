#!/bin/bash
#
# XML URL Encode Tool (纯 Shell 实现)
# 等效于 Python: urllib.parse.quote(s, safe='')
# 保留: A-Z a-z 0-9 - _ . ~
# 编码: 其他所有字符（包括空格、换行、中文、特殊符号等）
#
# Usage: ./xml_urlencode.sh <input_file> [output_file]

set -e

[ $# -lt 1 ] && echo "Usage: $0 <input_file> [output_file]" && exit 1

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}_encoded.${INPUT##*.}}"

[ ! -f "$INPUT" ] && echo "Error: File '$INPUT' not found" && exit 1

echo "处理: $INPUT"

# 优先做 XML 语法校验，避免把非法 XML 编码后再到学城报错
if command -v xmllint >/dev/null 2>&1; then
    if ! xmllint --noout "$INPUT" 2>/tmp/xml_lint_error.$$; then
        echo "Error: XML 语法不合法，已终止 URL 编码。"
        cat /tmp/xml_lint_error.$$
        rm -f /tmp/xml_lint_error.$$
        exit 1
    fi
    rm -f /tmp/xml_lint_error.$$
fi

# 使用 od 获取每个字节的十六进制值，然后用 awk 处理
# od -An -tx1 -v: 输出每个字节的十六进制，无地址，连续模式
# awk: 对每个字节判断是否安全字符，安全则输出原始字符，否则编码为 %XX
od -An -tx1 -v "$INPUT" | tr -d ' \n' | awk '
BEGIN {
    # 安全字符的十六进制值
    # 0-9: 30-39, A-Z: 41-5A, a-z: 61-7A, -: 2D, _: 5F, .: 2E, ~: 7E
    safe["30"]=1; safe["31"]=1; safe["32"]=1; safe["33"]=1; safe["34"]=1
    safe["35"]=1; safe["36"]=1; safe["37"]=1; safe["38"]=1; safe["39"]=1
    safe["41"]=1; safe["42"]=1; safe["43"]=1; safe["44"]=1; safe["45"]=1
    safe["46"]=1; safe["47"]=1; safe["48"]=1; safe["49"]=1; safe["4A"]=1
    safe["4B"]=1; safe["4C"]=1; safe["4D"]=1; safe["4E"]=1; safe["4F"]=1
    safe["50"]=1; safe["51"]=1; safe["52"]=1; safe["53"]=1; safe["54"]=1
    safe["55"]=1; safe["56"]=1; safe["57"]=1; safe["58"]=1; safe["59"]=1
    safe["5A"]=1
    safe["61"]=1; safe["62"]=1; safe["63"]=1; safe["64"]=1; safe["65"]=1
    safe["66"]=1; safe["67"]=1; safe["68"]=1; safe["69"]=1; safe["6A"]=1
    safe["6B"]=1; safe["6C"]=1; safe["6D"]=1; safe["6E"]=1; safe["6F"]=1
    safe["70"]=1; safe["71"]=1; safe["72"]=1; safe["73"]=1; safe["74"]=1
    safe["75"]=1; safe["76"]=1; safe["77"]=1; safe["78"]=1; safe["79"]=1
    safe["7A"]=1
    safe["2D"]=1; safe["5F"]=1; safe["2E"]=1; safe["7E"]=1

    # 十六进制到字符的映射
    hex2char["30"]="0"; hex2char["31"]="1"; hex2char["32"]="2"; hex2char["33"]="3"; hex2char["34"]="4"
    hex2char["35"]="5"; hex2char["36"]="6"; hex2char["37"]="7"; hex2char["38"]="8"; hex2char["39"]="9"
    hex2char["41"]="A"; hex2char["42"]="B"; hex2char["43"]="C"; hex2char["44"]="D"; hex2char["45"]="E"
    hex2char["46"]="F"; hex2char["47"]="G"; hex2char["48"]="H"; hex2char["49"]="I"; hex2char["4A"]="J"
    hex2char["4B"]="K"; hex2char["4C"]="L"; hex2char["4D"]="M"; hex2char["4E"]="N"; hex2char["4F"]="O"
    hex2char["50"]="P"; hex2char["51"]="Q"; hex2char["52"]="R"; hex2char["53"]="S"; hex2char["54"]="T"
    hex2char["55"]="U"; hex2char["56"]="V"; hex2char["57"]="W"; hex2char["58"]="X"; hex2char["59"]="Y"
    hex2char["5A"]="Z"
    hex2char["61"]="a"; hex2char["62"]="b"; hex2char["63"]="c"; hex2char["64"]="d"; hex2char["65"]="e"
    hex2char["66"]="f"; hex2char["67"]="g"; hex2char["68"]="h"; hex2char["69"]="i"; hex2char["6A"]="j"
    hex2char["6B"]="k"; hex2char["6C"]="l"; hex2char["6D"]="m"; hex2char["6E"]="n"; hex2char["6F"]="o"
    hex2char["70"]="p"; hex2char["71"]="q"; hex2char["72"]="r"; hex2char["73"]="s"; hex2char["74"]="t"
    hex2char["75"]="u"; hex2char["76"]="v"; hex2char["77"]="w"; hex2char["78"]="x"; hex2char["79"]="y"
    hex2char["7A"]="z"
    hex2char["2D"]="-"; hex2char["5F"]="_"; hex2char["2E"]="."; hex2char["7E"]="~"
}
{
    # 每两个字符是一个字节
    line = $0
    len = length(line)
    for (i = 1; i <= len; i += 2) {
        hex = substr(line, i, 2)
        # 转大写用于查找
        hex_upper = toupper(hex)
        if (safe[hex_upper]) {
            # 安全字符，输出原始字符
            printf "%s", hex2char[hex_upper]
        } else {
            # 不安全字符，输出 %XX 格式（大写）
            printf "%%%s", hex_upper
        }
    }
}
' > "$OUTPUT"

echo "完成: $OUTPUT ($(ls -lh "$OUTPUT" | awk '{print $5}'))"
head -c 100 "$OUTPUT"; echo "..."
