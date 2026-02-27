#include <getopt.h>

#include "zenith_backend/zenith_backend.hpp"

extern "C" {
#define static
#include <wlr/util/log.h>
#undef static
}

int main(int argc, char* argv[]) {
	wlr_log_init(WLR_DEBUG, nullptr);

	while ((getopt(argc, argv, "")) != -1);
	const char* startup_cmd = optind == argc ? "" : argv[optind];
	return zenith_backend_run(startup_cmd);
}
