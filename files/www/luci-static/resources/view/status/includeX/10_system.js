'use strict';
'require baseclass';
'require fs';
'require rpc';

var callLuciVersion = rpc.declare({object: 'luci', method: 'getVersion'});
var callSystemBoard = rpc.declare({object: 'system', method: 'board'});
var callSystemInfo = rpc.declare({object: 'system', method: 'info'});

return baseclass.extend({
	title: _('System'),
	load: function() {
		return Promise.all([
			L.resolveDefault(callSystemBoard(), {}),
			L.resolveDefault(callSystemInfo(), {}),
			L.resolveDefault(callLuciVersion(), {revision: _('unknown version'), branch: 'LuCI'}),
			L.resolveDefault(fs.read('/sys/class/thermal/thermal_zone0/temp'), null)
		]);
	},
	render: function(data) {
		var boardinfo = data[0],
		    systeminfo = data[1],
		    luciversion = data[2],
		    rawTemp = data[3];

		var modelStr = boardinfo.model || '?';
		var firmwareStr = (boardinfo.release && boardinfo.release.description) ? boardinfo.release.description : '?';
		var kernelStr = boardinfo.kernel || '?';

		var table = E('table', { 'class': 'table' });

		var updateTableRows = function(sysInfo, tempRaw) {
			var datestr = '-';
			var localTimestamp = sysInfo.localtime ? (sysInfo.localtime * 1000) : Date.now();
			var date = new Date(localTimestamp);
			if (!isNaN(date.getTime())) {
				datestr = '%04d-%02d-%02d %02d:%02d:%02d'.format(
					date.getFullYear(), date.getMonth() + 1, date.getDate(),
					date.getHours(), date.getMinutes(), date.getSeconds()
				);
			}

			var displayCPU = '0 %';
			if (sysInfo.load && Array.isArray(sysInfo.load) && sysInfo.load.length > 0) {

				var loadVal = sysInfo.load[0] / 65535.0; 
				var calc = Math.min(100, loadVal * 100);
				
				displayCPU = (calc > 0 && calc < 1) ? '1 %' : Math.ceil(calc) + ' %';
			}

			var cpuTemp = tempRaw ? (parseFloat(tempRaw) / 1000).toFixed(0) + '°C' : '-';

			var fields = [
				_('Model'),            modelStr,
				_('Firmware Version'), firmwareStr,
				_('Kernel Version'),   kernelStr,
				_('Local Time'),       datestr,
				_('Uptime'),           sysInfo.uptime ? '%t'.format(sysInfo.uptime) : '-',
				_('CPU Usage'),        displayCPU,
				_('Temperature'),      cpuTemp
			];

			table.innerHTML = '';

			for (var i = 0; i < fields.length; i += 2) {
				table.appendChild(E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'width': '33%' }, [fields[i]]),
					E('td', { 'class': 'td left' }, [(fields[i + 1] != null) ? fields[i + 1] : '?'])
				]));
			}
		};

		updateTableRows(systeminfo, rawTemp);

		L.Poll.add(function() {
			return Promise.all([
				L.resolveDefault(callSystemInfo(), {}),
				L.resolveDefault(fs.read('/sys/class/thermal/thermal_zone0/temp'), null)
			]).then(function(results) {
				updateTableRows(results[0], results[1]);
			});
		}, 3);

		return table;
	}
});
