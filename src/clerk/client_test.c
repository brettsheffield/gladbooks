#include "client_test.h"
#include "client.h"
#include "minunit.h"

#include <stdlib.h>

char *test_client_connect()
{
        mu_assert("Client connecting to server", 
                client_connect("::1", "3141") == 0);
        return 0;
}
