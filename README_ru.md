[<img src="https://raw.githubusercontent.com/lipis/flag-icons/refs/heads/main/flags/4x3/us.svg" height="14" /> English](README.md) | <img src="https://raw.githubusercontent.com/lipis/flag-icons/refs/heads/main/flags/4x3/ru.svg" height="14" /> `Русский`

# Pixel 8/Pro Kernel Builder: KernelSU & SUSFS

### ⚠️ Предупреждение
Как гласит лицензия MIT (см. файл `LICENSE`) - софт предоставляется "КАК ЕСТЬ". Никаких гарантий. Если ваш телефон окирпичится или уйдет в бутлуп, авторы ответственности не несут. Претензии не принимаются, всё делаете исключительно на свой страх и риск. 

### ⚙️ Что внутри
Сборка кастомного ядра со следующими интеграциями:
- **Root**: KernelSU
- **SUSFS**: пропатчено для скрытия рута
- **Baseband-guard**: LSM модуль для блокировки несанкционированной записи в критические разделы (защита модема/baseband)
- **Кастомная подпись менеджера**: менеджер с подменой имени пакета и приложения (spoofing) брать отсюда: [SvenLorence/KernelSU](https://github.com/SvenLorence/KernelSU)

Поддерживается сборка для Stable и Beta.

### 🛠️ Локальная сборка
Перед сборкой настоятельно рекомендуется ознакомиться с выводом справки и настроить файл `Variables.conf`.
```sh
./build_ksu.sh --help
```

Для сборки ядра на своем ПК используйте скрипт \`build_ksu.sh\`:
```sh
./build_ksu.sh --stable|--beta --ksu
```

### ⚡ Как шить (Установка)
1. Скачать подходящий `boot.img` из релизов.
2. Открыть терминал в папке со скачанным файлом.
3. Перевести телефон в режим bootloader и подключить к ПК.
4. Выполнить тестовую загрузку (чтобы проверить работоспособность ядра):
```sh
fastboot boot boot.img
```
5. Если система загрузилась успешно, снова перейти в bootloader и прошить окончательно:
```sh
fastboot flash boot boot.img
fastboot reboot
```