import * as React from "react";
import { useState, useEffect } from "react";
import { render } from "react-dom";

import { Audio } from 'react-loader-spinner'

import PlugConnect from '@psychedelic/plug-connect';


const App = () => {
  const [collections, setCollections] = useState([]);
  const [amt, setAmt] = useState(0);
  const [canister, setCanister] = useState("");
  const [encoding, setEncoding] = useState(null);
  const [tokens, setTokens] = useState([]);
  const [atokens, setAtokens] = useState([]);
  const [wallet, setWallet] = useState("");
  const [name, setName] = useState("");
  const [connect, setConnect] = useState("Please Connect you Wallet!");
  const [registry, setRegistry] = useState([]);
  const [nft, setNft] = useState(null);
  const [nft1, setNft1] = useState(null);
  const [nft_collection, setNftCollection] = useState("");
  const [token_index, setTokenIndex] = useState(0);
  const [loader, setLoader] = useState(false);
  const [address, setAddress] = useState("");
  const [prevent, setPrevent] = useState(false);
  const [json, setJson] = useState("");
  const [json1, setJson1] = useState("");
  const [nft_json, setNftJson] = useState("");

  const [url, setUrl] = useState("");
  const [nftType, setNftType] = useState("");
  const [nftType2, setNftType2] = useState("");
  const [burnt, setBurnt] = useState(0);
  const [burnt1, setBurnt1] = useState(0);

  const handleAmtChange = (event) => {
    const { value } = event.target;
    setAmt(value);
  };
  const handleCanChange = (event) => {
    const { value } = event.target;
    setCanister(value);
  };
  const handleEncodingChange = (event) => {
    const { value } = event.target;
    setEncoding(value);
  };

  const handlePreventChange = (event) => {
    if (event.target.checked) {
      setPrevent(true);
    }
    else {
      setPrevent(false)
    }
  };

  //plug connection and method call
  const deployerCanisterId = 'REPLACE THIS WITH YOUR CANISTER ID'
  const whitelist = [deployerCanisterId];

  const deployerIDL = ({ IDL }) => {
    const TokenIndex = IDL.Nat32;
    const AccountIdentifier = IDL.Text;
    const TokenIdentifier__1 = IDL.Text;
    const CommonError = IDL.Variant({
      'InvalidToken' : TokenIdentifier__1,
      'Other' : IDL.Text,
    });
    const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : CommonError });
    const AssetHandle = IDL.Text;
    const Info = IDL.Record({
      'status' : IDL.Text,
      'collection' : IDL.Text,
      'createdAt' : IDL.Int,
      'lowerBound' : TokenIndex,
      'upperBound' : TokenIndex,
      'burnAt' : IDL.Int,
    });
    const TokenIdentifier = IDL.Text;
    const ICHttpHeader = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
    const ICCanisterHttpResponsePayload = IDL.Record({
      'status' : IDL.Nat,
      'body' : IDL.Vec(IDL.Nat8),
      'headers' : IDL.Vec(ICHttpHeader),
    });
    const ICTransformArgs = IDL.Record({
      'context' : IDL.Vec(IDL.Nat8),
      'response' : ICCanisterHttpResponsePayload,
    });
    return IDL.Service({
      'airdrop_to_addresses' : IDL.Func(
          [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Bool, IDL.Int],
          [IDL.Vec(TokenIndex)],
          [],
        ),
      'batch_mint_to_address' : IDL.Func(
          [
            IDL.Text,
            AccountIdentifier,
            IDL.Text,
            IDL.Text,
            IDL.Text,
            IDL.Nat32,
            IDL.Int,
          ],
          [IDL.Vec(TokenIndex)],
          [],
        ),
      'burnNft' : IDL.Func(
          [IDL.Text, TokenIndex, AccountIdentifier],
          [Result],
          [],
        ),
      'burnNfts' : IDL.Func(
          [IDL.Text, TokenIndex, TokenIndex, AssetHandle],
          [],
          [],
        ),
      'clear_collection_registry' : IDL.Func([], [], []),
      'create_collection' : IDL.Func([IDL.Text, IDL.Text], [IDL.Text], []),
      'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
      'fetch_collection_addresses' : IDL.Func([IDL.Text], [], []),
      'getAID' : IDL.Func([], [AccountIdentifier], []),
      'getAddresses' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
      'getBurnInfo' : IDL.Func([IDL.Text], [IDL.Vec(Info)], ['query']),
      'getCaller' : IDL.Func([], [IDL.Text], []),
      'getCollections' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
      'getOwner' : IDL.Func([IDL.Text], [IDL.Text], ['query']),
      'getRegistry' : IDL.Func([IDL.Text], [IDL.Vec(IDL.Text)], []),
      'getTokenIdentifier' : IDL.Func(
          [IDL.Text, TokenIndex],
          [TokenIdentifier],
          [],
        ),
      'getTokenUrl' : IDL.Func([IDL.Text, TokenIndex], [IDL.Text], []),
      'kill_cron' : IDL.Func([], [], []),
      'transform' : IDL.Func(
          [ICTransformArgs],
          [ICCanisterHttpResponsePayload],
          ['query'],
        ),
      'wallet_receive' : IDL.Func([], [IDL.Nat], []),
    });
  };


  const getAllCollections = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    const deployerActor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });

    try {
      setLoader(true)
      const collection = await deployerActor.getCollections();
      const sessionData = window.ic.plug.sessionManager.sessionData;
      console.log(sessionData);
      setCollections(collection);
      setLoader(false)
      console.log(prevent);
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };
  const getRegistry = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    const deployerActor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });

    try {
      setLoader(true)
      const _registry = await deployerActor.getRegistry(String(canister));
      const sessionData = window.ic.plug.sessionManager.sessionData;
      console.log(sessionData);
      setRegistry(_registry);
      setLoader(false)
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };

  const batch_mint = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    const deployerActor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });
    const sessionData = window.ic.plug.sessionManager.sessionData;
    console.log(canister);
    console.log(encoding);
    console.log(amt);
    console.log(json1);
    console.log(address);
    console.log(nftType);
    console.log(burnt1);
    try {
      setLoader(true)
      const _req = []
      const mintedTokens = await deployerActor.batch_mint_to_address(String(canister), String(address), String(encoding), String(json1), String(nftType), Number(amt), BigInt(burnt1));
      setTokens(mintedTokens);
      setLoader(false)
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };

  const airdrop = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    const deployerActor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });
    const sessionData = window.ic.plug.sessionManager.sessionData;
    console.log(canister);
    console.log(sessionData.principalId);
    console.log(encoding);
    console.log(prevent);
    console.log(json);
    console.log(burnt);
    try {
      setLoader(true)
      const mintedTokens = await deployerActor.airdrop_to_addresses(String(nft_collection), String(canister), String(encoding), String(json), String(nftType2), Boolean(prevent), BigInt(burnt));
      setAtokens(mintedTokens);
      setLoader(false)
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };

  const handleCollectionCreation = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    alert("You need to transfer [0.33763252 ICP -><-  1T cycles (NFT Collection Canister)] + [0.0001 ICP -><- Transaction Fees] to Provider for creation of new collection.");

    try {
      const params = {
        to: 'REPLACE THIS WITH THE PRINCIPAL THAT RECEIVES THE ICP FOR PAYMENT OF CANISTER CREATION',
        amount: 35000000,      //HOW MUCH YOU CHARGE FOR PAYMENT OF CANISTER CREATION
        memo: 'charges for new canister creation',
      };
      const result = await window.ic.plug.requestTransfer(params);
      console.log(result);
    }
    catch (err) {
      alert(err);
      console.log(err);
      return;
    }
    const deployerActor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });

    try {
      setLoader(true)
      const sessionData = window.ic.plug.sessionManager.sessionData;
      const canisterId = await deployerActor.create_collection(name, String(sessionData.principalId));
      alert("Here is your nft collection : " + canisterId + "and Owner : " + (sessionData.principalId));
      setLoader(false)
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };

  const show_token_nft = async (event) => {
    const isConnected = await window.ic.plug.isConnected();
    if (!isConnected) {
      alert("Connect Plug Wallet!");
      return;
    }
    const actor = await window.ic.plug.createActor({
      canisterId: deployerCanisterId,
      interfaceFactory: deployerIDL,
    });

    try {
      setLoader(true)
      var url = await actor.getTokenUrl(String(canister), Number(token_index));
      setUrl(url);
      setLoader(false)
    }
    catch (err) {
      alert(err);
      setLoader(false)
    }
  };

  const ConnectCallback = async (event) => {
    setWallet(window.ic.plug.principalId);
    const isConnected = await window.ic.plug.isConnected();
    if (isConnected) {
      setConnect("Connected!");
    }
    else {
      setConnect("Please Connect you Wallet!");
    }
  };

  useEffect(() => {
    async function checkConnection() {
      const isConnected = await window.ic.plug.isConnected();
      if (isConnected) {
        setConnect("Connected!");
      }
    }
    checkConnection();
  }, []);


  return (
    <div style={{ "fontSize": "30px" }}>
      <div>
        <div style={{ display: "flex", justifyContent: "center", backgroundColor: "Black", position: "fixed", width: "100%" }}>
          <div style={{ marginRight: 50 }}>
            {
              loader && (<Audio
                height="30"
                width="30"
                radius="9"
                color='green'
                ariaLabel='three-dots-loading'
                wrapperStyle
                wrapperClass
              />)
            }
          </div>
          <div style={{ color: "Green", backgroundColor: "Yellow", marginRight: 100 }}>
            {connect}
          </div>
          <div>
            <PlugConnect
              whitelist={whitelist}
              onConnectCallback={ConnectCallback}
            />
          </div>
        </div>
        <br></br>
        <div style={{ marginTop: 50 }}>
          <div>Create Collection: (To create a new NFT collection)</div>
          <div><input
            name="name"
            placeholder="Collection Name"
            required
            onChange={(event) => setName(event.target.value)}
            value={name}
          ></input>
          </div>
          <button
            style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
            className=""
            onClick={handleCollectionCreation}>
            Create Collection!
          </button>
        </div>
        <br></br>
        <div>
          <div>
            List all created Collections and their Canister ID’s
          </div>
          <div>
            <button
              style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
              className=""
              onClick={getAllCollections}>
              All NFT Collection?
            </button>
            <div style={{ fontSize: 30, color: "Green", backgroundColor: "Yellow" }}>{collections}</div>
          </div>
        </div>
        <br></br>

        <div>
          <div>
            Check Token Registry of Collection
          </div>
          <div><input
            name="canisterID"
            placeholder="Collection Canister ID?"
            required
            onChange={handleCanChange}
          ></input></div>
          <div>
            <button
              style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
              className=""
              onClick={getRegistry}>
              Registry?
            </button>
            <div style={{ fontSize: 20, backgroundColor: "Yellow" }}>
              {registry}
            </div>
          </div>

        </div>

        <br></br>
        <br></br>



        <div>
          <div>Airdrop to Holders of an NFT Collection : </div>
          <div>
            {/* <div><input
              name="amt"
              type="number"
              placeholder="To how many?"
              required
              onChange={handleAmtChange}
            ></input></div> */}
            <label style={{ display: "flex" }}>
              <input
                type="checkbox"
                name="canisterID"
                onChange={handlePreventChange}
              ></input>
              <div style={{ fontSize: 20 }}>Prevent Duplicate Airdrop!</div>
            </label>
            <div><input
              name="canisterID"
              placeholder="Of which collection?"
              required
              onChange={(event) => setNftCollection(event.target.value)}
            ></input></div>
            <div><input
              name="canisterID"
              placeholder="To which collection?"
              required
              onChange={handleCanChange}

            ></input></div>
            <div style={{ display: "flex" }}>
              <div style={{ fontSize: 20 }}>
                NFT image
              </div>
              <div>
                {nft && (
                  <div>
                    <img alt="not found" width={"200px"} src={URL.createObjectURL(nft)} />
                    <button onClick={() => setNft(null)}>Remove</button>
                  </div>
                )}
                <input
                  type="file"
                  name="myImage"
                  onChange={(event) => {
                    const file = event.target.files[0];
                    const reader = new window.FileReader()
                    reader.onloadend = () => {
                      setNft(event.target.files[0]);
                      setEncoding(reader.result)
                      console.log(reader.result)
                    }
                    reader.readAsDataURL(file);
                  }}
                />
              </div>
            </div>
            <div><input
              name="json"
              placeholder="nft metadata?"
              required
              onChange={(event) => setJson(event.target.value)}
            ></input></div>
            <div><input
              name="Nft Type"
              placeholder="nft Type?"
              required
              onChange={(event) => setNftType2(event.target.value)}
            ></input></div>
            <div><input
              name="burn info"
              placeholder="Burn At?"
              required
              onChange={(event) => setBurnt(event.target.value)}
            ></input></div>
            <button
              style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
              className=""
              onClick={airdrop}>
              Airdrop!
            </button>
            <div style={{ color: "Green", backgroundColor: "Yellow" }}>{atokens}</div>
          </div>
        </div>



        <br></br>
        <br></br>




        <div>
          <div>Manually Mint to Address</div>
          <div>
            <div><input
              name="amt"
              type='number'
              placeholder="How many?"
              required
              onChange={handleAmtChange}
            ></input></div>
            <div><input
              name="Address"
              placeholder="To Whom?"
              required
              onChange={(event) => setAddress(event.target.value)}
            ></input></div>
            <div><input
              name="canisterID"
              placeholder="Collection Canister ID?"
              required
              onChange={handleCanChange}
            ></input></div>
            <div style={{ display: "flex" }}>
              <div style={{ fontSize: 20 }}>
                NFT image
              </div>
              <div>
                {nft1 && (
                  <div>
                    <img alt="not found" width={"200px"} src={URL.createObjectURL(nft1)} />
                    <button onClick={() => setNft1(null)}>Remove</button>
                  </div>
                )}
                <input
                  type="file"
                  name="myImage"
                  onChange={(event) => {
                    const file = event.target.files[0];
                    const reader = new window.FileReader()
                    reader.onloadend = () => {
                      setNft1(event.target.files[0]);
                      setEncoding(reader.result)
                      console.log(reader.result)
                    }
                    reader.readAsDataURL(file);
                  }}
                />
              </div>
            </div>
            <div><input
              name="json"
              placeholder="nft metadata?"
              required
              onChange={(event) => setJson1(event.target.value)}
            ></input></div>
            <div><input
              name="image type"
              placeholder="Type ?"
              required
              onChange={(event) => setNftType(event.target.value)}
            ></input></div>
            <div><input
              name="burn info"
              placeholder="Burn At ?"
              required
              onChange={(event) => setBurnt1(event.target.value)}
            ></input></div>
            <button
              style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
              className=""
              onClick={batch_mint}>
              Batch mint!
            </button>
            <div style={{ color: "Green", backgroundColor: "Yellow" }}>{tokens}</div>
          </div>
        </div>
        <br></br>
        <br></br>


        <div>
          <div>
            Check Minted NFT using TokenIndex : of a Collection
          </div>
          <div><input
            name="canisterID"
            placeholder="Collection Canister ID?"
            required
            onChange={handleCanChange}
          ></input></div>
          <div><input
            name="token_index"
            placeholder="Token Index?"
            required
            onChange={(event) => setTokenIndex(event.target.value)}
          ></input></div>
          <div>
            <button
              style={{ backgroundColor: "transparent", cursor: 'pointer', marginTop: 20, marginBottom: 20, width: 150, height: 30 }}
              className=""
              onClick={show_token_nft}>
              NFT?
            </button>
            <div style={{ fontSize: 20, backgroundColor: "Yellow" }}>
              <a href={url}
                target="_blank"
                rel="noreferrer">Show!</a>
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};

render(<App />, document.getElementById("app"));