function t_opf_userfcns(quiet)
%T_OPF_USERFCNS  Tests for userfcn callbacks (reserves/iflims) w/OPF.
%   Includes high-level tests of reserves and iflims implementations.

%   MATPOWER
%   $Id$
%   by Ray Zimmerman, PSERC Cornell
%   Copyright (c) 2009-2010 by Power System Engineering Research Center (PSERC)
%
%   This file is part of MATPOWER.
%   See http://www.pserc.cornell.edu/matpower/ for more info.
%
%   MATPOWER is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published
%   by the Free Software Foundation, either version 3 of the License,
%   or (at your option) any later version.
%
%   MATPOWER is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with MATPOWER. If not, see <http://www.gnu.org/licenses/>.
%
%   Additional permission under GNU GPL version 3 section 7
%
%   If you modify MATPOWER, or any covered work, to interface with
%   other modules (such as MATLAB code and MEX-files) available in a
%   MATLAB(R) or comparable environment containing parts covered
%   under other licensing terms, the licensors of MATPOWER grant
%   you additional permission to convey the resulting work.

if nargin < 1
    quiet = 0;
end

t_begin(51, quiet);

casefile = 't_case30_userfcns';
if quiet
    verbose = 0;
else
    verbose = 0;
end
mpopt = mpoption('opf.violation', 1e-6, 'mips.gradtol', 1e-8, ...
        'mips.comptol', 1e-8, 'mips.costtol', 1e-9);
mpopt = mpoption(mpopt, 'out.all', 0, 'verbose', verbose);
mpopt = mpoption(mpopt, 'opf.ac.solver', 'MIPS', 'opf.dc.solver', 'MIPS');
% mpopt = mpoption(mpopt, 'verbose', 2, 'out.all', -1, 'out.gen', 1);

[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%% run the OPF with fixed reserves
t = 'fixed reserves : ';
mpc = loadcase(casefile);
t_ok(~toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 0');
mpc = toggle_reserves(mpc, 'on');
t_ok(toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 1');
r = runopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_is(r.reserves.R, [25; 15; 0; 0; 19.3906; 0.6094], 4, [t 'reserves.R']);
t_is(r.reserves.prc, [2; 2; 2; 2; 5.5; 5.5], 4, [t 'reserves.prc']);
t_is(r.reserves.mu.Pmax, [0; 0; 0; 0; 0.5; 0], 4, [t 'reserves.mu.Pmax']);
t_is(r.reserves.mu.l, [0; 0; 1; 2; 0; 0], 4, [t 'reserves.mu.l']);
t_is(r.reserves.mu.u, [0.1; 0; 0; 0; 0; 0], 4, [t 'reserves.mu.u']);
t_ok(~isfield(r.if, 'P'), [t 'no iflims']);
t_is(r.reserves.totalcost, 177.8047, 4, [t 'totalcost']);

t = 'toggle_reserves(mpc, ''off'') : ';
mpc = toggle_reserves(mpc, 'off');
t_ok(~toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 0');
r = runopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_ok(~isfield(r.reserves, 'R'), [t 'no reserves']);
t_ok(~isfield(r.if, 'P'), [t 'no iflims']);

t = 'interface flow lims (DC) : ';
mpc = loadcase(casefile);
t_ok(~toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 0');
mpc = toggle_iflims(mpc, 'on');
t_ok(toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 1');
r = rundcopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_is(r.if.P, [-15; 20], 4, [t 'if.P']);
t_is(r.if.mu.l, [4.8427; 0], 4, [t 'if.mu.l']);
t_is(r.if.mu.u, [0; 13.2573], 4, [t 'if.mu.u']);
t_is(r.branch(14, PF), 8.244, 3, [t 'flow in branch 14']);
t_ok(~isfield(r.reserves, 'R'), [t 'no reserves']);

t = 'reserves + interface flow lims (DC) : ';
mpc = loadcase(casefile);
t_ok(~toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 0');
t_ok(~toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 0');
mpc = toggle_reserves(mpc, 'on');
t_ok(toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 1');
t_ok(~toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 0');
mpc = toggle_iflims(mpc, 'on');
t_ok(toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 1');
t_ok(toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 1');
r = rundcopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_is(r.if.P, [-15; 20], 4, [t 'if.P']);
t_is(r.if.mu.l, [4.8427; 0], 4, [t 'if.mu.l']);
t_is(r.if.mu.u, [0; 38.2573], 4, [t 'if.mu.u']);
t_is(r.reserves.R, [25; 15; 0; 0; 16.9; 3.1], 4, [t 'reserves.R']);
t_is(r.reserves.prc, [2; 2; 2; 2; 5.5; 5.5], 4, [t 'reserves.prc']);
t_is(r.reserves.mu.Pmax, [0; 0; 0; 0; 0.5; 0], 4, [t 'reserves.mu.Pmax']);
t_is(r.reserves.mu.l, [0; 0; 1; 2; 0; 0], 4, [t 'reserves.mu.l']);
t_is(r.reserves.mu.u, [0.1; 0; 0; 0; 0; 0], 4, [t 'reserves.mu.u']);
t_is(r.reserves.totalcost, 179.05, 4, [t 'totalcost']);

t = 'interface flow lims (AC) : ';
mpc = toggle_reserves(mpc, 'off');
t_ok(~toggle_reserves(mpc, 'status'), 'toggle_reserves(mpc, ''status'') == 0');
t_ok(toggle_iflims(mpc, 'status'), 'toggle_iflims(  mpc, ''status'') == 1');
r = runopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_is(r.if.P, [-9.101; 21.432], 3, [t 'if.P']);
t_is(r.if.mu.l, [0; 0], 4, [t 'if.mu.l']);
t_is(r.if.mu.u, [0; 10.198], 3, [t 'if.mu.u']);
t_ok(~isfield(r.reserves, 'R'), [t 'no reserves']);

t = 'interface flow lims (line out) : ';
mpc = loadcase(casefile);
mpc = toggle_iflims(mpc, 'on');
mpc.branch(12, BR_STATUS) = 0;      %% take out line 6-10
r = rundcopf(mpc, mpopt);
t_ok(r.success, [t 'success']);
t_is(r.if.P, [-15; 20], 4, [t 'if.P']);
t_is(r.if.mu.l, [4.8427; 0], 4, [t 'if.mu.l']);
t_is(r.if.mu.u, [0; 13.2573], 4, [t 'if.mu.u']);
t_is(r.branch(14, PF), 10.814, 3, [t 'flow in branch 14']);
t_ok(~isfield(r.reserves, 'R'), [t 'no reserves']);

% r.reserves.R
% r.reserves.prc
% r.reserves.mu.Pmax
% r.reserves.mu.l
% r.reserves.mu.u
% r.reserves.totalcost
% 
% r.if.P
% r.if.mu.l
% r.if.mu.u

t_end;
