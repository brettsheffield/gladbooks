#include "server_test.h"
#include "server.h"
#include "minunit.h"

char *test_server_start()
{
        mu_assert("Starting server", server_start() == 0);
        return 0;
}

char *test_server_stop()
{
        mu_assert("Stopping server", server_stop() == 0);
        return 0;
}
