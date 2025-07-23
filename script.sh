#!/bin/bash

DATE=$(date +"%d_%m_%Y")

wget "https://raw.githubusercontent.com/GreatMedivack/files/master/list.out"

if [ -z "$1" ]; then
    SERVER="test"
else
    SERVER="$1"
fi

RUNNING_OUT="${SERVER}_${DATE}_running.out"
FAILED_OUT="${SERVER}_${DATE}_failed.out"

while IFS= read -r line
do

    RNAME=$(echo "$line" | cut -d' ' -f1)
    STATUS=$(echo "$line" | tr -s " " | cut -d ' ' -f3)

    NAME=$(echo "$RNAME" | sed 's/-[0-9a-z]\{9,\}-[0-9a-z]\{5\}$//')

    if [ "$STATUS" = "Running" ]; then 
        echo "$NAME" >> "$RUNNING_OUT"
    elif [ "$STATUS" = "Error" ] || [ "$STATUS" = "CrashLoopBackOff" ]; then 
        echo "$NAME" >> "$FAILED_OUT"
    fi

done < list.out

sort -u -o "$RUNNING_OUT" "$RUNNING_OUT"
sort -u -o "$FAILED_OUT" "$FAILED_OUT"

REPORT_OUT="${SERVER}_${DATE}_report.out"

touch "$REPORT_OUT"
chmod 644 "$REPORT_OUT"

REP_DATE=$(date +"%d/%m/%Y")

echo "Количество работающих сервисов: $(wc -l < "$RUNNING_OUT")" >> "$REPORT_OUT"
echo "Количество сервисов с ошибками: $(wc -l < "$FAILED_OUT")" >> "$REPORT_OUT"
echo "Имя системного пользователя: $(whoami)" >> "$REPORT_OUT"
echo "Дата: "$REP_DATE"">> "$REPORT_OUT"

if [ ! -d "archives" ]; then
    mkdir archives
fi
ARCHIVE="${SERVER}_${DATE}.tar.gz"

if [ ! -f "archives/$ARCHIVE" ]; then
    tar -czf "archives/${ARCHIVE}" "$RUNNING_OUT" "$FAILED_OUT" "$REPORT_OUT"
    rm -f "list.out" "$FAILED_OUT" "$RUNNING_OUT" "$REPORT_OUT"
else 
    echo "Архив с таким именем уже существует"
    rm -f "list.out" "$FAILED_OUT" "$RUNNING_OUT" "$REPORT_OUT"
    exit 0
fi

if [ ! tar -tzf "$ARCHIVE" &>/dev/null ]; then
    echo "Архив поврежден"
else 
    echo "Успешное завершение работы"
fi
