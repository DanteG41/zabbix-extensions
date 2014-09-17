# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit eutils

DESCRIPTION="Zabbix additional monitoring modules"
HOMEPAGE="https://github.com/DanteG41/zabbix-extensions"
ZBX_EXT_GIT_SHA1="205346b"
SRC_URI="https://github.com/DanteG41/zabbix-extensions/tarball/${ZBX_EXT_GIT_SHA1} -> ${P}.tar.gz"
S="${WORKDIR}/DanteG41-${PN}-${ZBX_EXT_GIT_SHA1}"

LICENSE="as-is"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="flashcache glusterfs-client iostat keepalived memcached pgbouncer postfix postgres redis
sphinx2 skytools testcookie unicorn diskio smartmon ruby-vines resque"

HWRAID="adaptec smartarray megacli"

for name in ${HWRAID}; do
	IUSE+=" hwraid_${name}"
done

DEPEND=">=net-analyzer/zabbix-2.0.0
		app-admin/sudo
		iostat? ( app-admin/sysstat )
		keepalived? ( sys-apps/iproute2 )
		pgbouncer? ( dev-db/postgresql-base )
		postgres? ( dev-db/postgresql-base )
		redis? ( dev-db/redis )
		sphinx2? ( dev-db/mysql )
		skytools? ( dev-db/postgresql-base )
		hwraid_adaptec? ( sys-block/arcconf )
		hwraid_smartarray? ( sys-block/hpacucli )
		hwraid_megacli? ( sys-block/megacli )
		unicorn? ( net-misc/curl )
		smartmon? ( sys-apps/smartmontools )
		ruby-vines? ( dev-db/redis )"
RDEPEND="${DEPEND}"

src_install() {
	newconfd "${FILESDIR}"/zabbix-agentd-conf.d zabbix-agentd

	insinto /etc/zabbix/zabbix_agentd.d
	doins files/linux/linux-extended.conf

	exeinto /usr/libexec/zabbix-extensions/scripts
	doexe \
		files/linux/scripts/check-open-descriptors.sh \
		files/linux/scripts/mem-usage.sh \
		files/linux/scripts/swap.discovery.sh \
		files/linux/scripts/check-netif-speed.sh \
		files/linux/scripts/cave-pkg-discovery.sh

	insinto /etc/cron.d
	doins files/linux/zabbix.cron

	insinto /etc/sudoers.d
	newins files/linux/zabbix.sudo zabbix
	fperms 0440 /etc/sudoers.d/zabbix

	if use iostat; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/iostat/iostat.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
        doexe files/iostat/scripts/*.sh
	fi

	if use keepalived; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/keepalived/keepalived.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
		doexe \
			files/keepalived/scripts/keepalived.addr.discovery.sh \
			files/keepalived/scripts/keepalived.addr.availability.sh
	fi

	if use redis; then 
		insinto /etc/zabbix/zabbix_agentd.d
	    doins files/redis/redis.conf
	fi

	if use memcached; then 
		insinto /etc/zabbix/zabbix_agentd.d
	    doins files/memcached/memcached.conf
	fi

	if use pgbouncer; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/pgbouncer/pgbouncer.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
		doexe \
			files/pgbouncer/scripts/pgbouncer.pool.discovery.sh \
			files/pgbouncer/scripts/pgbouncer.stat.sh
	fi

	if use postfix; then 
		insinto /etc/zabbix/zabbix_agentd.d
	    doins files/postfix/postfix.conf
	fi

	if use postgres; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/postgresql/postgresql.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
		doexe \
			files/postgresql/scripts/pgsql.autovacuum.freeze.sh \
			files/postgresql/scripts/pgsql.buffercache.sh \
			files/postgresql/scripts/pgsql.connections.sh \
			files/postgresql/scripts/pgsql.db.discovery.sh \
			files/postgresql/scripts/pgsql.db.size.sh \
			files/postgresql/scripts/pgsql.dbstat.sh \
			files/postgresql/scripts/pgsql.indexes.size.sh \
			files/postgresql/scripts/pgsql.ping.sh \
			files/postgresql/scripts/pgsql.relation.size.sh \
			files/postgresql/scripts/pgsql.relation.stat.sh \
			files/postgresql/scripts/pgsql.relation.tuples.sh \
			files/postgresql/scripts/pgsql.streaming.lag.sh \
			files/postgresql/scripts/pgsql.transactions.sh \
			files/postgresql/scripts/pgsql.transactions.long.sh \
			files/postgresql/scripts/pgsql.uptime.sh \
			files/postgresql/scripts/pgsql.trigger.sh \
			files/postgresql/scripts/pgsql.wal.write.sh
	fi

	if use glusterfs-client; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/glusterfs-client/glusterfs.conf
        exeinto /usr/libexec/zabbix-extensions/scripts
        doexe \
            files/glusterfs-client/scripts/glusterfs.discovery.sh
	fi

	if use flashcache; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/flashcache/flashcache.conf
        exeinto /usr/libexec/zabbix-extensions/scripts
        doexe \
            files/flashcache/scripts/flashcache.dm.discovery.sh \
			files/flashcache/scripts/flashcache.vol.discovery.sh
    fi

	if use sphinx2; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/sphinx2/sphinx2.conf
    fi

	if use skytools; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/skytools/skytools.conf
        exeinto /usr/libexec/zabbix-extensions/scripts
        doexe \
            files/skytools/scripts/skytools.pgqd.queue.discovery.sh \
			files/skytools/scripts/skytools.pgqd.sh
    fi

	if use testcookie; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/testcookie/testcookie.conf
	fi

	if use hwraid_adaptec; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/hwraid-adaptec/adaptec.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
	    doexe \
			files/hwraid-adaptec/scripts/adaptec-raid-data-processor.sh \
			files/hwraid-adaptec/scripts/adaptec-adp-discovery.sh \
			files/hwraid-adaptec/scripts/adaptec-ld-discovery.sh \
			files/hwraid-adaptec/scripts/adaptec-pd-discovery.sh
		insinto /etc/cron.d
		doins files/hwraid-adaptec/zabbix.adaptec
	fi

	if use hwraid_smartarray; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/hwraid-smartarray/hp-raid-smart-array.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
	    doexe \
			files/hwraid-smartarray/scripts/hp-raid-data-processor.sh \
			files/hwraid-smartarray/scripts/hp-raid-ctrl-discovery.sh \
			files/hwraid-smartarray/scripts/hp-raid-ld-discovery.sh \
			files/hwraid-smartarray/scripts/hp-raid-pd-discovery.sh
		insinto /etc/cron.d
		doins files/hwraid-smartarray/zabbix.smartarray
	fi
	
	if use hwraid_megacli; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/hwraid-megacli/megacli.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
	    doexe \
			files/hwraid-megacli/scripts/megacli-adp-discovery.sh \
			files/hwraid-megacli/scripts/megacli-ld-discovery.sh \
			files/hwraid-megacli/scripts/megacli-pd-discovery.sh \
			files/hwraid-megacli/scripts/megacli-raid-data-processor.sh
		insinto /etc/cron.d
		doins files/hwraid-megacli/zabbix.megacli
	fi

	if use unicorn; then
		insinto /etc/zabbix/zabbix_agentd.d
        doins files/unicorn/unicorn.conf
    fi

	if use diskio; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/diskio/diskio.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
		doexe files/diskio/scripts/vfs.dev.discovery.sh
	fi

	if use smartmon; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/smartmon/smartmon.conf
	fi

	if use ruby-vines; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/ruby-vines/ruby-vines.conf
	fi

	if use resque; then
		insinto /etc/zabbix/zabbix_agentd.d
		doins files/resque/resque.conf
		exeinto /usr/libexec/zabbix-extensions/scripts
		doexe files/resque/scripts/old-resque-jobs.sh
	fi

}

pkg_postinst() {
	if use postgres || use skytools ; then
		elog 
		elog "For PostgreSQL or Skytools monitoring need setup md5 auth with .pgpass for zabbix user."
		elog "For example:"
		elog "# echo 'localhost:5432:app_db:app_role:app_pass' > ~zabbix/.pgpass"
		elog "# chown zabbix:zabbix ~zabbix/.pgpass"
		elog "# chmod 600 ~zabbix/.pgpass"
		elog
		elog "More explained: http://www.thislinux.org/2012/10/postgresql-monitoring-via-zabbix.html"
		elog
	fi

	if use hwraid_smartarray || use hwraid_megacli || use hwraid_adaptec; then
		elog
		elog "Hardware RAID monitoring extension uses crontask."
		elog "After install don't forget restart cron service manually."
		elog
	fi

	elog
	elog "After installation and before restart zabbix agent,"
	elog "make sure that the following option enabled in zabbix_agentd.conf:"
	elog "Include=/etc/zabbix/zabbix_agentd.d/"
	elog
}
