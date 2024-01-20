supdate: # Update submodules
	git submodule update --recursive --remote

sinit: # Initialize submodules after a clone
	git submodule init

setup: # Installs dependencies
	./rpi/install.sh

setup_rpi: # Installs dependencies on the pi
	./rpi/install.sh

ha: # Starts homeassistant
	cd rpi/homeassistant && docker compose up -d

hadown: # Stops homeassistant
	cd rpi/homeassistant && docker compose down
