/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


// Enums used as
// const states  = mirror["clean", "editable", "inserting"]
//
// Referenced as
//
//  states.clean, etc,.
//
//  From https://github.com/jh3y/key-book
//
//
function myenum(keys, prefix = '', suffix = '') {
    var aux = {};
    for (var k of keys) {
        var v = prefix + k + suffix;
        aux[v] = v;

    }
    return aux;
}
;

// isEmpty returns true if obj is null or empty ({}, [])

function isEmpty(obj) {
    for (var key in obj) {
        if (obj.hasOwnProperty(key))
            return false;
    }
    return true;
}

function isFunction(functionToCheck) {
    return functionToCheck && {}.toString.call(functionToCheck) === '[object Function]';
}
// dateSqlString converts a date to a string OK for sql
function dateSqlString(now) {
    var day = ("0" + now.getDate()).slice(-2);
    var month = ("0" + (now.getMonth() + 1)).slice(-2);

    var expr = now.getFullYear() + "-" + (month) + "-" + (day);
    return expr;
}

function stringComparator(a, b) {
    if (a < b) {
        return -1;
    } else if (a > b) {
        return 1;
    } else {
        return 0;
    }
}

// clne makes a deep copy or obj (normals obj's)

function clone(obj) {
    // Handle the 3 simple types, and null or undefined
    if (null == obj || "object" != typeof obj)
        return obj;

    // Handle Date
    if (obj instanceof Date) {
        var copy = new Date();
        copy.setTime(obj.getTime());
        return copy;
    }

    // Handle Array
    if (obj instanceof Array) {
        var copy = [];
        for (var i = 0, len = obj.length; i < len; i++) {
            copy[i] = clone(obj[i]);
        }
        return copy;
    }

    // Handle Object
    if (obj instanceof Object) {
        var copy = {};
        for (var attr in obj) {
            if (obj.hasOwnProperty(attr))
                copy[attr] = clone(obj[attr]);
        }
        return copy;
    }

    throw new Error("Unable to copy obj! Its type isn't supported.");
}

function formatNumber(num) {
    return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
}

function objectToString(obj){

    var str = "";
    
    for (var k of Object.keys(obj)){
        str += ", " + k + " : " + obj[k];
    }
    return str;
}

// Compara dos assentaments per ordre :
// Primer compte, desprès exercici, desprès asserntament
function comparadorAsientos(a, b) {

    if (a.CUENTA < b.CUENTA) {
        return -1;
    } else if (a.CUENTA > b.CUENTA) {
        return 1;
    } else {
        if (a.EJERCICIO < b.EJERCICIO) {
            return -1;
        } else if (a.EJERCICIO > b.EJERCICIO) {
            return 1;
        } else {
            if (a.FECHA < b.FECHA) {
                return -1;
            } else if (a.FECHA > b.FECHA) {
                return 1;
            } else {
                if (a.CODIGO < b.CODIGO) {
                    return -1;
                } else if (a.CODIGO > b.CODIGO) {
                    return 1;
                } else {
                    return 0;
                }
            }
        }
    }
}

/// Function for debouncionf keypresses by interval
/// add as debounce(callback function, interval) to keypress handler

function debounce(cb, interval, immediate) {
    var timeout;

    return function (event) {

        var context = this, args = arguments;
        var later = function () {
            timeout = null;
            if (!immediate)
                cb.apply(context, args);
        };

        var callNow = immediate && !timeout;

        clearTimeout(timeout);
        timeout = setTimeout(later, interval);

        if (callNow)
            cb.apply(context, args);
    };
}
;



// lookup searches the database for registers of table with conditions.
// conditions is a record where fieldname = table field and field value = table value
// for like statements use %25 instead of the %
//
// If all goes well onDOne is called ad onDone(data) where data is an array of objects with the results
// If ther is an error onError is called with (jqXHR, textStatus, errorThrown

function lookup(baseUrl, table, conditions, onDone, onError)
{

    var url = baseUrl + table;
    $('body').addClass('waiting');  // Waiting cursor
    var jqxhr =
            $.ajax({
                type: "GET",
                cache: false,
                dataType: "json",
                data: conditions,
                url: url,
            })
            .done(function (data) {
                var status = data[0];

                if (status.STATUS == "OK") {
                    onDone(data.slice(1));
                } else {
                    alert(status.MESSAGE);
                }
            })

            .fail(function (jqXHR, textStatus, errorThrown) {

                if (errorThrown != "abort") { // Abort fails silently :)
                    alert("Error at lookup" + textStatus + " " + errorThrown);
                }

            })
            .always(function () {
                $('body').removeClass('waiting');
            });

    return jqxhr;
}

function find(table, id, onDone, onError)
{

    var url = "/api/"+table+"/"+id;
    $('body').addClass('waiting');  // Waiting cursor
    var jqxhr =
            $.ajax({
                type: "GET",
                cache: false,
                dataType: "json",
                data: conditions,
                url: url,
            })
            .done(function (data) {
                var status = data[0];

                if (status.STATUS == "OK") {
                    onDone(data.slice(1));
                } else {
                    alert(status.MESSAGE);
                }
            })

            .fail(function (jqXHR, textStatus, errorThrown) {

                if (errorThrown != "abort") { // Abort fails silently :)
                    alert("Error at lookup" + textStatus + " " + errorThrown);
                }

            })
            .always(function () {
                $('body').removeClass('waiting');
            });

    return jqxhr;
}


function update(baseUrl, table, values, onDone, onError)
{

    var url = baseUrl + table;
    $('body').addClass('waiting');  // Waiting cursor
    var jqxhr =
            $.ajax({
                type: "POST",
                cache: false,
                dataType: "json",
                data: values,
                url: url
            })
            .done(function (data) {
                var status = data[0];

                if (status.STATUS == "OK") {
                    onDone(data.slice(1));
                } else {
                    alert(status.MESSAGE);
                }
            })

            .fail(function (jqXHR, textStatus, errorThrown) {

                if (errorThrown != "abort") { // Abort fails silently :)
                    alert("Error at lookup" + textStatus + " " + errorThrown);
                }

            })
            .always(function () {
                $('body').removeClass('waiting');
            });

    return jqxhr;
}

function deleteRecord(baseUrl, table, values, onDone, onError)
{

    var url = baseUrl + table;
    $('body').addClass('waiting');  // Waiting cursor
    var myData = clone(values); // Just don't mess with passed records
    myData._method="DELETE";
    var jqxhr =
            $.ajax({
                type: "POST",
                cache: false,
                dataType: "json",
                data: myData,
                url: url
            })
            .done(function (data) {
                var status = data[0];

                if (status.STATUS === "OK") {
                    onDone(data);
                } else {
                    alert(status.MESSAGE);
                }
            })

            .fail(function (jqXHR, textStatus, errorThrown) {

                if (errorThrown !== "abort") { // Abort fails silently :)
                    alert("Error at lookup" + textStatus + " " + errorThrown);
                }

            })
            .always(function () {
                $('body').removeClass('waiting');
            });

    return jqxhr;
}
function insert(baseUrl, table, values, onDone, onError)
{

    var url = baseUrl + table;
    $('body').addClass('waiting');  // Waiting cursor
    var myData = clone(values); // Just don't mess with passed records
    myData._method="PUT";
    var jqxhr =
            $.ajax({
                type: "POST",
                cache: false,
                dataType: "json",
                data: myData,
                url: url
            })
            .done(function (data) {
                var status = data[0];

                if (status.STATUS === "OK") {
                    onDone(data.slice(1));
                } else {
                    alert(status.MESSAGE);
                }
            })

            .fail(function (jqXHR, textStatus, errorThrown) {

                if (errorThrown !== "abort") { // Abort fails silently :)
                    alert("Error at lookup" + textStatus + " " + errorThrown);
                }

            })
            .always(function () {
                $('body').removeClass('waiting');
            });

    return jqxhr;
}

// Construeix el body de la  taula body a partir de un query de table, amb conditions.
// Una columna per cada entrada a fields i ordenats els resultats en funcio de la funcio sorter.
// conditions es un record con NOMBRE_DE_CAMPO : valor
// fields es un array a on cada entrada pot ser NOMBRE de CAMPO o {field:<campo>, type:<number | date | string>}  o
// una funció que reb el registre i ha de generar tota la casella de la taula, començant per el <TD> i acabant per el </TD>
// sorter es una funcio que reb dos registres de resultat a, b i retorna -a ai a < b, 0 si a = b, 1 si a> b a on la relacio
// implica l'ordre de displya

function tableBuilder(baseUrl, table, conditions, fields, sorter, body, after) {
    return lookup(baseUrl, table, conditions,
            function (data) {
                data.sort(sorter);
                body.empty();
                for (const rec of data) {
                    var line = "<tr>";
                    for (const f of fields) {
                        var v;
                        var fu;

                        if (isFunction(f)) {
                            line += f(rec);
                        } else if (typeof f === 'object') {
                            v = rec[f.field];
                            fu = f.onClick;
                            var onclick = "";

                            if (fu != "" && !isEmpty(fu)) {
                                onclick = " class=\"link\" onclick='" + fu + "(\"" + v + "\");'"
                            }

                            if (f.type === 'number') {
                                line += "<TD align=\"right\" " + onclick + ">" + formatNumber(v) + "</TD>"
                            } else if (f.type === 'date') {
                                v = rec[f.field];
                                var x = v.substring(0, 10);
                                line += "<TD align=\"right\" " + onclick + ">" + x + "</TD>"
                            } else {
                                line += "<TD" + onclick + ">" + v + "</TD>";
                            }
                        } else {
                            v = rec[f];
                            //if (isNaN(v)) {
                            line += "<TD>" + v + "</TD>";
                            //} else {
                            //    line += "<TD align=\"right\">" + formatNumber(v) + "</TD>";
                            //}

                        }
                    }
                    line += "</tr>\n";
                    body.append(line);
                }
                if (after != null) {
                    after(data);
                }
            },
            function (jqXHR, textStatus, errorThrown) {
                alert("Error loading " + tabla + " " + textStatus + " " + errorThrown);
            });
}

// Builds some popups from table an fields valor, descripcion.
// Popups are in an array at descripcion and are jQuery objects.
//
// Must define <SELECT id="my_my_field_id"></SELECT> in the html portion
//
// tabla is the table we must lookup for datam
// valor is the code field that will be used a s value
// descripcion is the textual value displayed
// camnpos is an array of fields we must update.
//
//  Although usually we only have one popup per table sometimes we may have many


function loadPopup(baseUrl, tabla, valor, descripcion, campos, reverse)
{
    var url = baseUrl + tabla;

    lookup(baseUrl, tabla, {},
            function (data) {

                if (reverse != null) {
                    data.sort(function (a, b) {
                        var res = 0;

                        if (a[descripcion] < b[descripcion]) {
                            res = -1;
                        } else if (a[descripcion] > b[descripcion]) {
                            res = 1;
                        } else {
                            res = 0;
                        }

                        if (reverse) {
                            return res * -1;
                        } else {
                            return res;
                        }
                    });
                }
                for (var reg in data)
                {
                    var lin = data[reg];
                    var desc = lin[descripcion];
                    var vl = lin[valor];
                    var txt = "<option value='" + vl + "'>" + desc + "</option>";

                    for (var ix in campos)
                    {
                        var f = campos[ix];
                        $(f).append(txt);
                    }
                }
            },
            function (jqXHR, textStatus, errorThrown) {
                alert("Error loading " + tabla + " " + textStatus + " " + errorThrown);
            });

}

