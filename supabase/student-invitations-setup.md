# Приглашение ученика через Telegram

Функция создаёт ожидающее подтверждения приглашение и одноразовую ссылку `t.me/MaxiEnglish_bot?start=...`. При первом нажатии Start Telegram передаёт боту Telegram ID и имя ученика; webhook подтверждает запись и отвечает кнопкой открытия MaxiEnglish.

## 1. Применить SQL

Откройте Supabase Dashboard → SQL Editor и выполните содержимое `student-confirmation-and-history.sql`. Он рассчитан на уже настроенные приглашения и схему после `student-invitations.sql`. Миграция добавляет подтверждение приглашения, скрывает ожидающих учеников, сохраняет имя из Telegram и включает внесение начального баланса и прошедших занятий. Её можно запускать повторно.

Если приглашения ещё не настраивались, сначала выполните `student-invitations.sql`, затем `student-confirmation-and-history.sql`. Если вы ещё не запускали `lesson-links.sql`, выполните его отдельно, чтобы включить поле Zoom в настройках учителя.

## 2. Обновить токен бота

Токен бота ранее попал в переписку. Сначала перевыпустите его через BotFather, затем сохраните новый токен в Supabase вместе с секретом webhook. Не добавляйте токен в исходники проекта.

В терминале из папки проекта выполните блок целиком. Вставьте новый токен в скрытый ввод, когда терминал попросит:

```zsh
(
  set -e
  read -rs "TELEGRAM_BOT_TOKEN?Новый токен из BotFather: "
  printf '\n'
  TELEGRAM_WEBHOOK_SECRET="$(openssl rand -hex 32)"
  npx supabase secrets set \
    "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" \
    "TELEGRAM_WEBHOOK_SECRET=$TELEGRAM_WEBHOOK_SECRET" \
    --project-ref gxcpnixtjqpjgonpidix
  npx supabase functions deploy telegram-bot-webhook --project-ref gxcpnixtjqpjgonpidix
  npx supabase functions deploy link-telegram --project-ref gxcpnixtjqpjgonpidix
  curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
    --data-urlencode 'url=https://gxcpnixtjqpjgonpidix.supabase.co/functions/v1/telegram-bot-webhook' \
    --data-urlencode "secret_token=$TELEGRAM_WEBHOOK_SECRET" \
    --data-urlencode 'allowed_updates=["message"]'
  curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
)
```

В ответе `setWebhook` должно быть `"ok":true`; в `getWebhookInfo` поле `url` должно содержать адрес функции, а `last_error_message` должно отсутствовать или быть пустым.

## 3. Опубликовать интерфейс

Из папки проекта:

```sh
npm run build
npx firebase-tools@latest deploy --only hosting
```

После этого учитель создаёт ссылку в приложении и отправляет её. Ученик открывает именно эту ссылку в Telegram и нажимает кнопку Start на странице бота. Вручную набранная команда `/start` не содержит код приглашения и не привязывает профиль. Ссылка действует 7 дней и активируется одним Telegram-аккаунтом. В шаге 2 разворачивается обновлённый webhook, который сохраняет имя из Telegram.

Когда ученик подтвердит приглашение, он появится в списке. В его карточке учитель сможет добавить ссылку на доску и число оплаченных занятий, купленных до приложения. Прошедшие уроки нужно внести в календаре с отметкой «Урок уже прошёл» — каждый такой урок списывает одно занятие.
