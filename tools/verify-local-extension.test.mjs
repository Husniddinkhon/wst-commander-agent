import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import http from 'node:http';
import {checkLocalMcp,verify} from './verify-local-extension.mjs';

test('authenticates and checks registered tools without returning secrets',async t=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'wst-ext-test-'));
 t.after(()=>fs.rm(root,{recursive:true,force:true}));
 const tokenFile=path.join(root,'token');
 const token='A'.repeat(64);
 await fs.writeFile(tokenFile,token);
 const server=http.createServer((req,res)=>{
  if(req.headers.authorization!==`Bearer ${token}`){res.writeHead(401).end();return}
  res.writeHead(200,{'content-type':'application/json'});
  res.end(JSON.stringify({jsonrpc:'2.0',id:1,result:{tools:[{name:'wst_ext_health'},{name:'wst_ext_read'}]}}))
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 t.after(()=>new Promise(resolve=>server.close(resolve)));
 const url=`http://127.0.0.1:${server.address().port}`;
 const ok=await checkLocalMcp({url,tokenFile,expectedNames:['wst_ext_health','wst_ext_read']});
 assert.equal(ok.status,'ok');
 assert.equal(ok.toolCount,2);
 assert.equal(JSON.stringify(ok).includes(token),false);
 const partial=await checkLocalMcp({url,tokenFile,expectedNames:['wst_ext_health','wst_ext_write']});
 assert.equal(partial.status,'partial');
 assert.deepEqual(partial.missing,['wst_ext_write']);
});

test('missing bearer token fails safely',async()=>{
 const result=await checkLocalMcp({tokenFile:'/nonexistent-wst-extension-token'});
 assert.deepEqual(result,{status:'failed',reason:'local_token_unavailable'});
});

test('local healthy is not evidence of remote parity',async()=>{
 const result=await verify({tcp:async()=>true,checkMcp:async()=>({status:'ok',toolCount:30,missing:[]})});
 assert.equal(result.remoteGatewayMcp.status,'not_verified');
 assert.equal(result.parity,'not_verified');
});
