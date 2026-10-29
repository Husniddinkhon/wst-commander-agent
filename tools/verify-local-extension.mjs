#!/usr/bin/env node
/**
 * Read-only verification of the WST Commander localhost MCP extension.
 * NEVER prints the local bearer token, performs mutations, or claims
 * remote gateway parity from localhost port checks.
 */
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import { fileURLToPath } from 'node:url';

const DEFAULT_PORTS = [4318, 4319, 4320];
const REQUIRED_NAMES = ['wst_ext_health','wst_ext_list','wst_ext_read','wst_ext_write','wst_ext_screenshot','wst_ext_mouse_click','wst_ext_keyboard_text','wst_ext_shell'];

export function testTcp(host, port, timeoutMs=2500) {
  return new Promise(resolve => {
    const s = net.createConnection({host,port});
    let settled = false;
    const done = ok => {if(settled)return;settled=true;s.destroy();resolve(ok)};
    s.setTimeout(timeoutMs);
    s.once('connect',()=>done(true));
    s.once('error',()=>done(false));
    s.once('timeout',()=>done(false));
  });
}

export async function checkLocalMcp({
  url='http://127.0.0.1:4320',
  tokenFile=path.join(process.env.LOCALAPPDATA||os.tmpdir(),'WSTCommanderExtension','.extension-token'),
  expectedNames=REQUIRED_NAMES,
  fetchImpl=fetch,
}={}) {
  let token;
  try {token=(await fs.readFile(tokenFile,'utf8')).trim()}
  catch {return {status:'failed',reason:'local_token_unavailable'}}
  if(!token||token.length<20)return {status:'failed',reason:'local_token_invalid'};
  const controller=new AbortController();
  const timeout=setTimeout(()=>controller.abort(),6000);
  try {
    const res=await fetchImpl(`${url}/mcp`,{
      method:'POST',
      headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json',Accept:'application/json, text/event-stream'},
      body:JSON.stringify({jsonrpc:'2.0',id:1,method:'tools/list',params:{}}),
      signal:controller.signal,
    });
    if(!res.ok)return {status:'failed',reason:`mcp_http_${res.status}`};
    const rpc=await res.json();
    if(!Array.isArray(rpc?.result?.tools))return {status:'failed',reason:'missing_tools_array'};
    const names=rpc.result.tools.map(x=>x.name).filter(x=>typeof x==='string');
    const missing=expectedNames.filter(x=>!names.includes(x));
    return {status:missing.length?'partial':'ok',toolCount:names.length,missing,note:'Tool discovery only; permissions and remote routing not verified.'};
  }catch{return {status:'failed',reason:'local_mcp_unreachable_or_invalid'}}
  finally{clearTimeout(timeout)}
}

export async function verify({ports=DEFAULT_PORTS,checkMcp=checkLocalMcp,tcp=testTcp}={}) {
  const localPorts=Object.fromEntries(await Promise.all(ports.map(async port=>[String(port),await tcp('127.0.0.1',port)])));
  const localMcp=localPorts['4320']?await checkMcp():{status:'failed',reason:'port_4320_closed'};
  return {
    timestamp:new Date().toISOString(),
    computer:os.hostname(),
    localPorts,
    localMcp,
    remoteGatewayMcp:{status:'not_verified',reason:'Requires authenticated remote tool discovery and an approved paired-agent relay.'},
    parity:'not_verified',
  };
}

if(process.argv[1] && path.resolve(fileURLToPath(import.meta.url))===path.resolve(process.argv[1])){
  const result=await verify();
  console.log(JSON.stringify(result,null,2));
  process.exitCode=Object.values(result.localPorts).some(v=>!v)||result.localMcp.status!=='ok'?1:0;
}
