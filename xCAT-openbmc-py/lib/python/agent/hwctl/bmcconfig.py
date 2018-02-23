#!/usr/bin/env python
###############################################################################
# IBM(c) 2018 EPL license http://www.eclipse.org/legal/epl-v10.html
###############################################################################
# -*- coding: utf-8 -*-
#

class BmcConfigInterface(object):
    """Interface for bmc configuration related actions."""
    interface_type = 'bmcconfig'
    version = '1.0'

    def dump_list(self, task):
        return task.run('dump_list')

    def dump_generate(self, task):
        return task.run("dump_generate")

    def dump_clear(self, task, id):
        return task.run("dump_clear", id)

    def dump_download(self, task, id):
        return task.run("dump_download", id)

    def dump_process(self, task):
        return task.run("dump_process")

    def set_sshcfg(self, task):
        return task.run("set_sshcfg")

    def set_ipdhcp(self, task):
        return task.run("set_ipdhcp")

    def get_attributes(self, task, attributes):
        return task.run("get_attributes", attributes)

    def set_attributes(self, task, attributes):
        return task.run("set_attributes", attributes)

class DefaultBmcConfigManager(BmcConfigInterface):
    """Interface for BmcConfig actions."""
    pass