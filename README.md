# seeredis
Web application to see the data stored in a Redis instance.
This was a quick experiment to see how easy could it be to port existing [WSAPI](http://keplerproject.github.io/wsapi/) applications to run with [OpenResty](https://openresty.org/).

The application is fully functional, but ugly looking :)

# Installing

You need to have OpenResty installed. I tested with 1.9.7.3. Go grab it [here](https://openresty.org/#Download). Once it is installed, clone this repository.

    git clone https://github.com/ignacio/seeredis.git

Install [LuaRocks](https://luarocks.org) if you haven't already, since we need to install a couple of Lua modules:

    luarocks install wsapi-openresty
    luarocks install webrender --server=https://luarocks.org/manifests/ignacio

Edit `conf/develop.conf` and adjust the path to OpenResty's libraries. Then start the service:

    /path/to/openresty/nginx -c conf/develop.conf -p /path/to/seeredis

Finally, navigate with your browser to:

    http://127.0.0.1

Then, indicate the IP/port of the running Redis instance that you want to inspect and hit "Connect".

# Why?

Well, this was just a proof of concept. The idea was to port an already existing Lua application, which was coded against _WSAPI_, to run on _OpenResty_. Since there wasn't any existing WSAPI connector for OpenRest, [I wrote one](https://github.com/ignacio/wsapi-openresty).

The only "big" change that was needed was to use [lua-resty-redis](https://github.com/openresty/lua-resty-redis) instead of the current blocking client.

# Author

Ignacio Burgueño - [@iburgueno](https://twitter.com/iburgueno) - https://uy.linkedin.com/in/ignacioburgueno

# License

MIT/X11
