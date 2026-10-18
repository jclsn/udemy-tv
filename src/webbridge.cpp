// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "webbridge.h"

#include "udemyclient.h"

void WebBridge::attach()
{
    UdemyClient::instance()->bridgeAttached();
}

void WebBridge::deliver(int id, int status, const QString &body)
{
    UdemyClient::instance()->deliver(id, status, body);
}
