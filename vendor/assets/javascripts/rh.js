(function () {
  'use strict';

 
  var max_fr_tick = 150;
  var max_rh_tick = 120;

  var rh_gravity = 8;
  var rh_min_dist_joint = 30;
  var dist_arr = [];
  var longest_dist = 1800;
  var min_dist = 80;
  var fr_string_strength = 80*3;
  var fr_string_drag = 30*3;
  var rh_string_strength = 140;
  var rh_string_drag = 0; // How much drag is on the string?
  var max_rh_links = 5000;
  var fr_repulstion = 0.3;
  var rh_repulstion = -1.5;
  var too_small_size = 300;
  var width = 2000;
  var height = 1000;
  var center_x = width * 0.5;
  var center_y = height * 0.5;
  var radius = 5;

  var avgDist = function (nodes, center_x, center_y) {
    var x = [];
    var y = [];
    var x_sum = 0, y_sum = 0;
    var tmp_x, tmp_y;
    var live_x = 0, live_y = 0;
    var avg_x, avg_y;
    var is_particles = true;
    _.forEach(nodes, function (node) {
      if (!node.p) {
        is_particles = false;
        return;
      }
      tmp_x = Math.abs(node.p.position.x);
      tmp_y = Math.abs(node.p.position.y);
      x.push(Math.abs(tmp_x - center_x));
      y.push(Math.abs(tmp_y - center_y));
    });
    if (!is_particles) {
      return;
    }
    _.forEach(x, function (_x) {
      if (_x) {
        x_sum += _x;
        live_x++;
      }
    });
    _.forEach(y, function (_y) {
      if (_y) {
        y_sum += _y;
        live_y++;
      }
    });
    avg_x = Math.abs(x_sum / live_x);
    avg_y = Math.abs(y_sum / live_y);

    return [avg_x, avg_y];
  };
  var startRH = function (graph, weights, callback) {
    var log_scale = d3.scale.linear().domain([_.min(weights), _.max(weights)]).range([1, 3]);

    var mass = 4000;
    var drag = 750;
    var physics = new Physics(0, drag);
    physics.optimize(true);

    var num_of_nodes = _.size(graph.nodes);
    //create physics particle for each node
    for (var i = 0; i < num_of_nodes; i++) {
      graph.nodes[i]['p'] = physics.makeParticle(mass, graph.nodes[i].x, graph.nodes[i].y);
      graph.nodes[i].related = [];
    }

    var nodes_as_arr = function (nodes) {
      var arr = [];
      _.forEach(nodes, function (node) {
        arr.push(node);
      });
      return arr;
    };

    var nodes_arr = nodes_as_arr(graph.nodes);

    //create minimal repulsion between all the nodes
    var baseRepulsion = function (nodes_arr) {

      if (nodes_arr.length === 0) {
        return;
      }
      var head = _.first(nodes_arr);
      var tail = _.rest(nodes_arr);
      _.forEach(tail, function (node) {
        physics.makeAttraction(head.p, node.p, rh_repulstion, 15);

      });
      baseRepulsion(tail);
    };
    baseRepulsion(nodes_arr);

    var joint = {};

    var springConnection = function (graph) {
      var nodes = graph.nodes;
      var edges = graph.links;
      var joint_id = 0;
      _.forEach(edges, function (edge) {
        var pre_source = _.find(nodes, function (node) {
          return node.unique_id === edge.source;
        });
        var pre_target = _.find(nodes, function (node) {
          return node.unique_id === edge.target;
        });
        if (!pre_source || !pre_target) {
          return;
        }
        var y = (pre_source.y + pre_target.y ) / 2;
        var x = (pre_source.x + pre_target.x ) / 2;
        var rest = Math.sqrt(Math.pow(pre_source.x - pre_target.x, 2) + Math.pow(pre_source.y - pre_target.y, 2));
        dist_arr.push(rest)
      });

      var normalize_dist = d3.scale.linear().domain([_.min(dist_arr), _.max(dist_arr)]).range([
        80, longest_dist / 3
      ]);
      _.forEach(edges, function (edge) {
        var pre_source = _.find(nodes, function (node) {
          return node.unique_id === edge.source;
        });
        var pre_target = _.find(nodes, function (node) {
          return node.unique_id === edge.target;
        });
        if (!pre_source || !pre_target) {
          return;
        }
        var source = pre_source.p;
        var target = pre_target.p;

        var y = (pre_source.y + pre_target.y ) / 2;
        var x = (pre_source.x + pre_target.x ) / 2;
        var rest = Math.sqrt(Math.pow(pre_source.x - pre_target.x, 2) + Math.pow(pre_source.y - pre_target.y, 2));
        joint[joint_id] = {};
        joint[joint_id].weight = edge.weight || 0;
        joint[joint_id].p = physics.makeParticle(mass / 5, x, y);
        var half_distance = normalize_dist(rest / log_scale(joint[joint_id].weight));
        physics.makeSpring(source, target, 1, 0, half_distance * 2);
        physics.makeSpring(source, joint[joint_id].p, rh_string_strength
          , rh_string_drag, half_distance);
        physics.makeSpring(target, joint[joint_id].p, rh_string_strength
          , rh_string_drag, half_distance);
        joint[joint_id].from = pre_source.id;
        joint[joint_id].from_group_id = pre_source.group_id;
        joint[joint_id].to = pre_target.id;
        joint[joint_id].cliq_id = edge.cliq_id;

        joint_id++
      })
    };

    springConnection(graph);

    var shalow_rh_conection = function () {
      var i = 0;
      var join_arr = _.take(_.toArray(joint), max_rh_links);
      _.forEach(join_arr, function (jo) {
        join_arr = _.tail(join_arr);
        i = i + 1;
        if (i > max_rh_links) {
          return
        }
        var j = 0;
        var jo = jo;
        _.forEach(join_arr, function (jok) {
          j = j + 1;
          if (j > max_rh_links) {
            return
          }
          if ((jo.from !== jok.from && jo.to == jok.from) || (jok.from !== jo.from && jok.to == jo.from)) {
            physics.makeAttraction(jo.p, jok.p, rh_gravity, rh_min_dist_joint);
          }
        })
      })
    };

    shalow_rh_conection();

    var RHtick = 0;
    var render = function () {
      var nodes = graph.nodes;
      var edges = graph.links;
      if (RHtick > 30) {
        var avg_dist_from_center = avgDist(nodes, center_x, center_y);
        if (avg_dist_from_center && (Math.abs(avg_dist_from_center[0]) < too_small_size || Math.abs(avg_dist_from_center[1]) < too_small_size)) {

          rh_string_strength = rh_string_strength * 0.2;
          rh_string_drag += 5;
          rh_repulstion = rh_repulstion - 65;
          rh_gravity += rh_gravity * 1.5;
        _.forEach(nodes, function (node, idx) {
            delete node.p;
          });

          var print = {
            "nodes": nodes,
            "links": edges
          };
          if(physics){
          physics.clear();
          physics = null;
          }
          startRH(print, weights, callback);
          return;
        }
      }
      if (RHtick > max_rh_tick) {
        if (physics) {
          physics.clear();
          physics = null;
        }
        _.forEach(graph.nodes, function (node) {
          if (!node.p) {
            return
          }
          node.x = node.p.position.x;
          node.y = node.p.position.y;
          delete node.p;
        });
        callback(graph.nodes);
      }
      RHtick++;
      var nodes = graph.nodes;
      var edges = graph.links;
      var x;
      var y;
    
      _.forEach(nodes, function (node, idx) {
        if (!nodes[idx].p) {
          return
        }
        x = nodes[idx].p.position.x;
        y = nodes[idx].p.position.y;
      });

    
      //if it seems that graph get explode  than
      if (Math.abs(x - center_x) > 100000 || Math.abs(y - center_y) > 100000) {

        var avg_dist_from_center = avgDist(nodes, center_x, center_y);
        if (avg_dist_from_center && (Math.abs(avg_dist_from_center[0]) > 1000 || Math.abs(avg_dist_from_center[1]) > 1000)) {
          rh_string_strength = rh_string_strength * 0.5;
          rh_string_drag = rh_string_drag * 0.5;
          _.forEach(nodes, function (node, idx) {
            delete node.p;
          });

          var print = {
            "nodes": nodes,
            "links": edges
          };
          if(physics){
          physics.clear();
          physics = null;
        
          }
      
          startRH(print, weights, callback);
        }

      }

    };

    // Bind the render function to when physics updates.
    physics.onUpdate(render);

    // Render a posterframe.
    render();
    physics.play();

  };

  var startFR = function (json_src, callback) {

    var graph = json_src;
    var weights = [];
      //create unique id for the nodes
      _.forEach(graph.nodes, function (node) {
        node.type = node.type || '';
        node.unique_id = (node.id).toString() + node.type;
      });

      _.forEach(graph.links, function (link) {
        link.from_type = link.from_type || '';
        link.to_type = link.to_type || '';
        link.source = link.from_id.toString() + link.from_type;
        link.target = link.to_id.toString() + link.to_type;
        if (link.weight) {
          weights.push(link.weight)
        }
      });

      var log_scale = d3.scale.pow().domain([_.min(weights), _.max(weights)]).range([1, 10]);
 
      var mass = 1050;
      var drag = 40;
      var physics = new Physics(0, drag);
      physics.optimize(true);

      var num_of_nodes = _.size(graph.nodes);
      for (var i = 0; i < num_of_nodes; i++) {
        if (i % 2 == 0) {
          graph.nodes[i]['p'] = physics.makeParticle(mass, center_x + (i % 44) * 2, center_y + (i % 33) * 2)
        } else {
          graph.nodes[i]['p'] = physics.makeParticle(mass, center_x - (i % 44) * 2, center_y - (i % 33) * 2)
        }

      }

      var nodes_as_arr = function (nodes) {
        var arr = [];
        _.forEach(nodes, function (node) {
          arr.push(node);
        });
        return arr;
      };
      var nodes_arr = nodes_as_arr(graph.nodes);

      var size_of_links = _.size(graph.links);

      // Make the attraction and add it to physics
      var baseRepulsion = function (nodes_arr) {
        if (nodes_arr.length === 0) {
          return
        }
        var head = _.first(nodes_arr);
        var tail = _.rest(nodes_arr);

        _.forEach(tail, function (node) {

          physics.makeSpring(head.p, node.p, fr_repulstion, 0, longest_dist);//41

        });
        baseRepulsion(tail);
      };
      baseRepulsion(nodes_arr);
      var string_strength = fr_string_strength;
    
      var rest = 50;

      var springConnection = function (graph) {
        var nodes = graph.nodes;
        var edges = graph.links;
        _.forEach(edges, function (edge) {
          var source = _.find(nodes, function (node) {
            return node.unique_id === edge.source;
          });
          var target = _.find(nodes, function (node) {
            return node.unique_id === edge.target;
          });
          var source = source.p;
          var target = target.p;
          physics.makeSpring(source, target, string_strength, fr_string_drag, rest);
 
        })

      };

      springConnection(graph);
      var one_time = false;
      var FRtick = 0;
      var isResting = function (nodes) {

        _.forEach(nodes, function (node) {
          if (Math.abs(node.x - node.prev_x) < 0.001) {
            arr_resting.push(0)
          } else {
            arr_resting.push(-1)
          }
 
        })

      };
      //firsrt we render with FR for basic setup
      var render = function () {
        FRtick++;
 
        var nodes = graph.nodes;
        var edges = graph.links;
        if (FRtick > max_fr_tick/2 && !one_time) {
          var avg_dist_from_center = avgDist(nodes, center_x, center_y);
          if (avg_dist_from_center && (Math.abs(avg_dist_from_center[0]) < too_small_size || Math.abs(avg_dist_from_center[1]) < too_small_size)) {

            fr_string_strength = fr_string_strength * 0.2;

            fr_repulstion += 17;
            if(physics){
            physics.clear();
            physics = null;
            }
            _.forEach(graph.nodes, function (node) {
              if (!node.p) {
                return
              }

              delete node.p;
            });
            startFR(graph, callback);
           
          }
        }
        if (FRtick > max_fr_tick && !one_time) {
          var avg_dist_from_center = avgDist(nodes, center_x, center_y);
          if (avg_dist_from_center && (Math.abs(avg_dist_from_center[0]) < too_small_size || Math.abs(avg_dist_from_center[1]) < too_small_size)) {

            fr_string_strength = fr_string_strength * 0.2;
            fr_repulstion += 17;
            if(physics){
            physics.clear();
            physics = null;
            }
         
            _.forEach(graph.nodes, function (node) {
              if (!node.p) {
                return
              }

              delete node.p;
            });
            startFR(graph, callback);
            return;
          }
          if (one_time) {
            return
          }
          one_time = 1;
          _.forEach(nodes, function (node, idx) {
            delete node.p;
          });

          var print = {
            "nodes": nodes,
            "links": edges
          };
          if(physics){
              physics.clear();
          physics = null;
          }
        
          var avg_dist_from_center = avgDist(nodes, center_x, center_y);
          startRH(print, weights, callback);
          
        }
        if (one_time) {
          return
        }
 

        _.forEach(nodes, function (node, idx) {
        
          if (!nodes[idx].p) {
            return
          }
          var x = nodes[idx].p.position.x;
          var y = nodes[idx].p.position.y;
          node.x = nodes[idx].p.position.x;
          node.y = nodes[idx].p.position.y;

          node.prev_x = nodes[idx].p.position.x;
          node.prev_y = nodes[idx].p.position.y;
    

          //if it seems that graph get explode  than
          if (Math.abs(x - center_x) > 10000 || Math.abs(y - center_y) > 10000) {
            var avg_dist_from_center = avgDist(nodes, center_x, center_y);
            if (Math.abs(avg_dist_from_center[0]) > 1000 || Math.abs(avg_dist_from_center[1]) > 1000) {

              fr_string_strength = fr_string_strength * 0.4;
              fr_string_drag = fr_string_drag * 0.4;

              rh_string_strength = rh_string_strength * 0.4;
              rh_string_drag = rh_string_drag * 0.4;
              if(physics){
                 physics.clear();
              physics = null;
              }
             
              _.forEach(graph.nodes, function (node) {
                if (!node.p) {
                  return
                }

                delete node.p;
              });
              startFR(graph, callback);
            }
          }

        });

      };

      // Bind the render function to when physics updates.
      physics.onUpdate(render);
      // Render a posterframe.
      render();

      physics.play();

  };
  window.rh = {startFR: startFR};
})();