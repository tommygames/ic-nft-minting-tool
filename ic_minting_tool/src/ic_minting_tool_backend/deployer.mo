import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Char "mo:base/Char";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";


import Timer "mo:base/Timer";   

import NFT "./EXT/v2";
import AID "./utils/AccountIdentifier";
import ExtCore "./utils/Core";
import ExtCommon "./utils/Common";
import ExtAllowance "./utils/Allowance";
import ExtNonFungible "./utils/NonFungible";
import AccountIdentifier "utils/AccountIdentifier";

//Cap
import Cap "./Cap/Cap";
import Queue "./utils/Queue";
import EXTAsset "./EXT/extAsset";
import Core "utils/Core";
import Types "Cap/Types";
import Base32 "utils/Principal/base32";

actor Deployer {
    type EXTAssetService = EXTAsset.EXTAsset;
    type Order = { #less; #equal; #greater };
    type Time = Time.Time;
    type AccountIdentifier = ExtCore.AccountIdentifier;
    type SubAccount = ExtCore.SubAccount;
    type User = ExtCore.User;
    type Balance = ExtCore.Balance;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type TokenIndex = ExtCore.TokenIndex;
    type Extension = ExtCore.Extension;
    type CommonError = ExtCore.CommonError;
    type BalanceRequest = ExtCore.BalanceRequest;
    type BalanceResponse = ExtCore.BalanceResponse;
    type TransferRequest = ExtCore.TransferRequest;
    type TransferResponse = ExtCore.TransferResponse;
    type AllowanceRequest = ExtAllowance.AllowanceRequest;
    type ApproveRequest = ExtAllowance.ApproveRequest;
    type MetadataLegacy = ExtCommon.Metadata;
    type NotifyService = ExtCore.NotifyService;
    type MintingRequest = {
        to : AccountIdentifier;
        asset : Nat32;
    };

    type MetadataValue = (
        Text,
        {
            #text : Text;
            #blob : Blob;
            #nat : Nat;
            #nat8 : Nat8;
        },
    );
    type MetadataContainer = {
        #data : [MetadataValue];
        #blob : Blob;
        #json : Text;
    };
    type Metadata = {
        #fungible : {
            name : Text;
            symbol : Text;
            decimals : Nat8;
            metadata : ?MetadataContainer;
        };
        #nonfungible : {
            name : Text;
            asset : Text;
            thumbnail : Text;
            metadata : ?MetadataContainer;
        };
    };

    //Marketplace
    type Transaction = {
        token : TokenIndex;
        seller : AccountIdentifier;
        price : Nat64;
        buyer : AccountIdentifier;
        time : Time;
    };
    type Listing = {
        seller : Principal;
        price : Nat64;
        locked : ?Time;
    };
    type ListRequest = {
        token : TokenIdentifier;
        from_subaccount : ?SubAccount;
        price : ?Nat64;
    };

    //LEDGER
    type AccountBalanceArgs = { account : AccountIdentifier };
    type ICPTs = { e8s : Nat64 };
    type SendArgs = {
        memo : Nat64;
        amount : ICPTs;
        fee : ICPTs;
        from_subaccount : ?SubAccount;
        to : AccountIdentifier;
        created_at_time : ?Time;
    };

    //Cap
    type CapDetailValue = {
        #I64 : Int64;
        #U64 : Nat64;
        #Vec : [CapDetailValue];
        #Slice : [Nat8];
        #Text : Text;
        #True;
        #False;
        #Float : Float;
        #Principal : Principal;
    };
    type CapEvent = {
        time : Nat64;
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };
    type CapIndefiniteEvent = {
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };

    //Sale
    type PaymentType = {
        #sale : Nat64;
        #nft : TokenIndex;
        #nfts : [TokenIndex];
    };
    type Payment = {
        purchase : PaymentType;
        amount : Nat64;
        subaccount : SubAccount;
        payer : AccountIdentifier;
        expires : Time;
    };
    type SaleTransaction = {
        tokens : [TokenIndex];
        seller : Principal;
        price : Nat64;
        buyer : AccountIdentifier;
        time : Time;
    };
    type SaleDetailGroup = {
        id : Nat;
        name : Text;
        start : Time;
        end : Time;
        available : Bool;
        pricing : [(Nat64, Nat64)];
    };
    type SaleDetails = {
        start : Time;
        end : Time;
        groups : [SaleDetailGroup];
        quantity : Nat;
        remaining : Nat;
    };
    type SaleSettings = {
        price : Nat64;
        salePrice : Nat64;
        sold : Nat;
        remaining : Nat;
        startTime : Time;
        whitelistTime : Time;
        whitelist : Bool;
        totalToSell : Nat;
        bulkPricing : [(Nat64, Nat64)];
    };
    type SalePricingGroup = {
        name : Text;
        limit : (Nat64, Nat64); //user, group
        start : Time;
        end : Time;
        pricing : [(Nat64, Nat64)]; //qty,price
        participants : [AccountIdentifier];
    };
    type SaleRemaining = { #burn; #send : AccountIdentifier; #retain };
    type Sale = {
        start : Time; //Start of first group
        end : Time; //End of first group
        groups : [SalePricingGroup];
        quantity : Nat; //Tokens for sale, set by 0000 address
        remaining : SaleRemaining;
    };

    //EXTv2 Asset Handling
    type AssetHandle = Text;
    type AssetId = Nat32;
    type ChunkId = Nat32;
    type AssetType = {
        #canister : {
            id : AssetId;
            canister : Text;
        };
        #direct : [ChunkId];
        #other : Text;
    };
    type Asset = {
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };
    type Asset_req = {
        assetHandle : Text;
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };

    //HTTP
    type HeaderField = (Text, Text);
    type HttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        streaming_strategy : ?HttpStreamingStrategy;
        upgrade : Bool;
    };
    type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };
    type HttpStreamingCallbackToken = {
        content_encoding : Text;
        index : Nat;
        key : Text;
        sha256 : ?Blob;
    };
    type HttpStreamingStrategy = {
        #Callback : {
            callback : query (HttpStreamingCallbackToken) -> async (HttpStreamingCallbackResponse);
            token : HttpStreamingCallbackToken;
        };
    };
    type HttpStreamingCallbackResponse = {
        body : Blob;
        token : ?HttpStreamingCallbackToken;
    };

    //IC Management Canister HTTP
    type ICTx = {
        height : Nat64;
        to : Text;
        from : Text;
        amt : Nat64;
    };

    type ICHttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        upgrade : ?Bool;
    };

    type ICHttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };

    type ICHttpHeader = {
        name : Text;
        value : Text;
    };

    type ICHttpMethod = {
        #get;
        #post;
        #head;
    };

    type ICTransformType = {
        #function : shared ICCanisterHttpResponsePayload -> async ICCanisterHttpResponsePayload;
    };

    type ICTransformArgs = {
        response : ICCanisterHttpResponsePayload;
        context : Blob;
    };

    type ICTransformContext = {
        function : shared query ICTransformArgs -> async ICCanisterHttpResponsePayload;
        context : Blob;
    };

    type ICCanisterHttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [ICHttpHeader];
        body : [Nat8];
        method : ICHttpMethod;
        transform : ?ICTransformContext;
    };

    type ICCanisterHttpResponsePayload = {
        status : Nat;
        headers : [ICHttpHeader];
        body : [Nat8];
    };

    type ICResponse = {
        #Success : Text;
        #Err : Text;
    };

    //Batch Information
    type Info = {
        collection : Text;
        createdAt : Int;
        burnAt : Int;
        lowerBound : TokenIndex;
        upperBound : TokenIndex;
        status : Text;
    };

    private stable var deployerID : Principal = Principal.fromText("REPLACE THIS WITH YOUR CANISTER ID");

    private var init_minter : Principal = deployerID;

    private stable var collections : Trie.Trie<Text, Text> = Trie.empty(); //mapping of Collection CanisterID -> Collection Name
    private stable var _owner : Trie.Trie<Text, Text> = Trie.empty(); //mapping collection canister id -> owner principal id
    private stable var _info : Trie.Trie<AssetHandle, Info> = Trie.empty(); //mapping asset hanel -> Burn Information
    private stable var addresses : [Text] = [];

    type NFT = NFT.EXTNFT;
    public type canister_id = Principal;
    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    public type user_id = Principal;
    public type wasm_module = Blob;

    private func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };

    private func keyT(x : Text) : Trie.Key<Text> {
        return { hash = Text.hash(x); key = x };
    };

    //IC Management Canister.
    let IC = actor ("aaaaa-aa") : actor {
        canister_status : shared { canister_id : canister_id } -> async {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : definite_canister_settings;
            module_hash : ?[Nat8];
        };
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        delete_canister : shared { canister_id : canister_id } -> async ();
        deposit_cycles : shared { canister_id : canister_id } -> async ();
        install_code : shared {
            arg : Blob;
            wasm_module : wasm_module;
            mode : { #reinstall; #upgrade; #install };
            canister_id : canister_id;
        } -> async ();
        provisional_create_canister_with_cycles : shared {
            settings : ?canister_settings;
            amount : ?Nat;
        } -> async { canister_id : canister_id };
        provisional_top_up_canister : shared {
            canister_id : canister_id;
            amount : Nat;
        } -> async ();
        raw_rand : shared () -> async [Nat8];
        start_canister : shared { canister_id : canister_id } -> async ();
        stop_canister : shared { canister_id : canister_id } -> async ();
        uninstall_code : shared { canister_id : canister_id } -> async ();
        update_settings : shared {
            canister_id : Principal;
            settings : canister_settings;
        } -> async ();
        http_request : shared ICCanisterHttpRequestArgs -> async ICCanisterHttpResponsePayload;
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    private func create_canister() : async (Text) {
        Cycles.add(1000000000000);
        let canister = await NFT.EXTNFT(init_minter);
        let _ = await updateCanister(canister);
        let canister_id = Principal.fromActor(canister);
        return Principal.toText(canister_id);
    };

    private func updateCanister(a : actor {}) : async () {
        let cid = { canister_id = Principal.fromActor(a) };
        var principal : Text = "REPLACE THIS WITH YOUR CANISTER ID THAT GETS GENERATED FOR THIS TOOL";
        var owner : Text = "";
        var wallet_can : Text = "";

        await (
            IC.update_settings({
                canister_id = cid.canister_id;
                settings = {
                    controllers = ?[Principal.fromText(principal)];
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            }),
        );
    };
    public func wallet_receive() : async Nat {
        Cycles.accept(Cycles.available());
    };

    public shared (msg) func create_collection(collectionName : Text, creator : Text) : async (Text) {
        var canID : Text = await create_canister();
        collections := Trie.put(collections, keyT(canID), Text.equal, collectionName).0;
        _owner := Trie.put(_owner, keyT(canID), Text.equal, creator).0;
        return canID;
    };

    public query func getCollections() : async ([Text]) {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for ((id, name) in Trie.iter(collections)) {
            var data : Text = name # " -> " #id # " ,";
            buffer.add(data);
        };
        return buffer.toArray();
    };

    public func getRegistry(collection_canister_id : Text) : async ([Text]) {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        let collection = actor (collection_canister_id) : actor {
            getRegistry : () -> async [(TokenIndex, AccountIdentifier)];
        };
        var _registry : [(TokenIndex, AccountIdentifier)] = await collection.getRegistry();
        for ((index, add) in _registry.vals()) {
            var data : Text = Nat32.toText(index) # " : " #add # " ,";
            buffer.add(data);
        };
        return buffer.toArray();
    };

    public query func getAddresses() : async ([Text]) {
        return addresses;
    };

    public shared (msg) func batch_mint_to_address(collection_canister_id : Text, aid : AccountIdentifier, encoding : Text, j : Text, _ctype : Text, mint_size : Nat32, _burnAt : Int) : async ([TokenIndex]) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        assert (msg.caller == Principal.fromText(owner));
        var _json : MetadataContainer = #json j;
        var _atype : AssetType = #other encoding;
        var _reg : [Text] = await getRegistry(collection_canister_id);
        var size : Nat = _reg.size();
        var _req : (AccountIdentifier, Metadata) = (
            aid,
            #nonfungible {
                name = "";
                asset = "nftAsset:" #collection_canister_id # (Nat.toText(size));
                thumbnail = encoding;
                metadata = ?_json;
            },
        );
        var _assetReq : Asset_req = {
            assetHandle = "nftAsset:" #collection_canister_id # (Nat.toText(size));
            ctype = _ctype;
            filename = "";
            atype = _atype;
        };
        var indices : Buffer.Buffer<TokenIndex> = Buffer.Buffer<TokenIndex>(0);
        var i : Nat32 = 0;
        //updating asset
        await addAsset(collection_canister_id, _assetReq.assetHandle, _assetReq.ctype, _assetReq.filename, _assetReq.atype, 0);
        var _lowerBound : TokenIndex = 0;
        var _upperBound : TokenIndex = 0;
        while (i < mint_size) {
            //minting nft
            var token_id : TokenIndex = await mintNft(collection_canister_id, _req);
            indices.add(token_id);
            _upperBound := token_id;
            i += 1;
        };
        _lowerBound := _upperBound - mint_size + 1;
        var info : Info = {
            collection = collection_canister_id;
            createdAt = Time.now();
            burnAt = _burnAt;
            lowerBound = _lowerBound;
            upperBound = _upperBound;
            status = "active";
        };
        _info := Trie.put(_info, keyT(_assetReq.assetHandle), Text.equal, info).0;
        return indices.toArray();
    };

    public func fetch_collection_addresses(canister_id : Text) : async () {
        let collection = actor (canister_id) : actor {
            getRegistry : () -> async ([(TokenIndex, AccountIdentifier)]);
        };
        var new_addresses : [(TokenIndex, AccountIdentifier)] = await collection.getRegistry();
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (unit in addresses.vals()) {
            buffer.add(unit);
        };
        for ((token_index, account_identifier) in new_addresses.vals()) {
            buffer.add(account_identifier);
        };
        addresses := buffer.toArray();
    };

    public shared (msg) func airdrop_to_addresses(collection_canister_id : Text, canid : Text, encoding : Text, j : Text, _ctype : Text, prevent : Bool, _burnAt : Int) : async ([TokenIndex]) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(canid), Text.equal), "");
        assert (msg.caller == Principal.fromText(owner));

        var _json : MetadataContainer = #json j;
        var _atype : AssetType = #other encoding;
        var _reg : [Text] = await getRegistry(collection_canister_id);
        var size : Nat = _reg.size();

        var i : Nat = 0;
        var indices : Buffer.Buffer<TokenIndex> = Buffer.Buffer<TokenIndex>(0);
        let collection = actor (collection_canister_id) : actor {
            getRegistry : () -> async [(TokenIndex, AccountIdentifier)];
        };
        var fetched_addresses : [(TokenIndex, AccountIdentifier)] = await collection.getRegistry();
        var total_mints : Nat = fetched_addresses.size();
        // switch (mint_size) {
        //     case (?s) {
        //         if (fetched_addresses.size() < Nat32.toNat(s)) {
        //             total_mints := fetched_addresses.size();
        //         } else {
        //             total_mints := Nat32.toNat(s);
        //         };
        //     };
        //     case _ {};
        // };
        let airdrop_mapping = HashMap.HashMap<AccountIdentifier, Bool>(0, Text.equal, Text.hash); //mapping address to bool, to prevent duplicate airdrops.
        var _assetReq : Asset_req = {
            assetHandle = "nftAsset:" #canid # (Nat.toText(size));
            ctype = _ctype;
            filename = "";
            atype = _atype;
        };
        await addAsset(canid, _assetReq.assetHandle, _assetReq.ctype, _assetReq.filename, _assetReq.atype, 0);
        var _lowerBound : TokenIndex = 0;
        var _upperBound : TokenIndex = 0;
        while (i < total_mints) {
            var id : (TokenIndex, AccountIdentifier) = fetched_addresses[i];
            var _req : (AccountIdentifier, Metadata) = (
                id.1,
                #nonfungible {
                    name = "";
                    asset = "nftAsset:" #canid # (Nat.toText(size));
                    thumbnail = encoding;
                    metadata = ?_json;
                },
            );
            if (prevent == false) {
                var token_id : TokenIndex = await mintNft(canid, _req);
                _upperBound := token_id;
                indices.add(token_id);
            } else {
                var isPresent : Bool = Option.get(airdrop_mapping.get(id.1), false);
                if (isPresent == false) {
                    var token_id : TokenIndex = await mintNft(canid, _req);
                    _upperBound := token_id;
                    indices.add(token_id);
                    airdrop_mapping.put(id.1, true);
                };
            };
            i := i + 1;
        };
        _lowerBound := _upperBound - Nat32.fromNat(total_mints) + 1;
        var info : Info = {
            collection = canid;
            createdAt = Time.now();
            burnAt = _burnAt;
            lowerBound = _lowerBound;
            upperBound = _upperBound;
            status = "active";
        };
        _info := Trie.put(_info, keyT(_assetReq.assetHandle), Text.equal, info).0;
        return indices.toArray();
    };

    public query func getBurnInfo(collection_canister_id : Text) : async [Info] {
        var buffer : Buffer.Buffer<Info> = Buffer.Buffer<Info>(0);
        for ((id, info) in Trie.iter(_info)) {
            if (info.collection == collection_canister_id) {
                buffer.add(info);
            };
        };
        return Buffer.toArray(buffer);
    };

    public shared (msg) func clear_collection_registry() : async () {
        assert (msg.caller == Principal.fromText("REPLACE THIS WITH YOUR CANISTER ID"));
        collections := Trie.empty();
        _owner := Trie.empty();
    };

    public shared ({ caller }) func getTokenUrl(collection_canister_id : Text, token_index : TokenIndex) : async (Text) {
        var tokenid : TokenIdentifier = await getTokenIdentifier(collection_canister_id, token_index);
        return "https://" #collection_canister_id # ".raw.ic0.app/?&tokenid=" #tokenid;
    };

    public func getTokenIdentifier(t : Text, i : TokenIndex) : async (TokenIdentifier) {
        return Core.TokenIdentifier.fromText(t, i);
    };

    public query func getOwner(id : Text) : async (Text) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(id), Text.equal), "");
        return owner;
    };
    public shared ({ caller }) func getCaller() : async (Text) {
        Principal.toText(caller);
    };

    private func mintNft(collection_canister_id : Text, _req : (AccountIdentifier, Metadata)) : async TokenIndex {
        // var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        // assert (msg.caller == Principal.fromText(owner));
        let collection = actor (collection_canister_id) : actor {
            ext_mint : ([(AccountIdentifier, Metadata)]) -> async ([TokenIndex]);
        };
        var b : Buffer.Buffer<(AccountIdentifier, Metadata)> = Buffer.Buffer<(AccountIdentifier, Metadata)>(0);
        b.add(_req);
        var a : [TokenIndex] = await collection.ext_mint(Buffer.toArray(b));
        return a[0];
    };

    private func addAsset(collection_canister_id : Text, assetHandle : AssetHandle, ctype : Text, filename : Text, atype : AssetType, size : Nat) : async () {
        // var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        // assert (msg.caller == Principal.fromText(owner));
        let collection = actor (collection_canister_id) : actor {
            ext_assetAdd : (AssetHandle, Text, Text, AssetType, Nat) -> async ();
        };
        await collection.ext_assetAdd(assetHandle, ctype, filename, atype, size);
    };

    public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : TokenIndex, aid : AccountIdentifier) : async (Result.Result<(?Text), CommonError>) {
        assert (AccountIdentifier.fromPrincipal(msg.caller, null) == aid);
        var tokenid : TokenIdentifier = await getTokenIdentifier(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_burn : (TokenIdentifier, AccountIdentifier) -> async (Result.Result<(), CommonError>);
            extGetTokenMetadata : (TokenIndex) -> async (?Metadata);
        };
        var res : Result.Result<(), CommonError> = await collection.ext_burn(tokenid, aid);
        switch (res) {
            case (#ok) {
                return #ok();
            };
            case (#err(e)) {
                return #err(e);
            };
        };
    };

    public shared(msg) func burnNfts(collection_canister_id : Text, _lowerBound : TokenIndex, _upperBound : TokenIndex, assetHandle : AssetHandle) : async () {
        // var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        assert (msg.caller == Principal.fromText("REPLACE THIS WITH YOUR CANISTER ID"));
        var l : Nat32 = _lowerBound;
        var u : Nat32 = _upperBound;
        while (l <= u) {
            var tokenindex : TokenIndex = l;
            var tokenid : TokenIdentifier = await getTokenIdentifier(collection_canister_id, tokenindex);
            let collection = actor (collection_canister_id) : actor {
                extGetTokenMetadata : (TokenIndex) -> async (?Metadata);
                ext_internal_burn : (TokenIdentifier) -> async (Result.Result<(), CommonError>);
            };
            var res : Result.Result<(), CommonError> = await collection.ext_internal_burn(tokenid);
            switch (res) {
                case (#ok) {
                    return #ok();
                };
                case (#err(e)) {};
            };
            l := l + 1;
        };
        var i : ?Info = Trie.find(_info, keyT(assetHandle), Text.equal);
        switch (i) {
            case (?i) {
                var new_i : Info = {
                    collection = i.collection;
                    createdAt = i.createdAt;
                    burnAt = i.burnAt;
                    lowerBound = i.lowerBound;
                    upperBound = i.upperBound;
                    status = "burned";
                };
                _info := Trie.put(_info, keyT(assetHandle), Text.equal, new_i).0;
            };
            case _ {};
        };
    };

    func burn_cron() : async () {
        for ((id, info) in Trie.iter(_info)) {
            if (info.burnAt < Time.now() and info.status == "active") {
                await burnNfts(info.collection, info.lowerBound, info.upperBound, id);
            };
        };
    };

    //Outgoing http_calls
    //
    public query func transform(raw : ICTransformArgs) : async ICCanisterHttpResponsePayload {
        let transformed : ICCanisterHttpResponsePayload = {
            status = 200;
            body = raw.response.body;
            headers = [];
        };
        transformed;
    };

    public shared (msg) func getAID() : async AccountIdentifier {
        return AccountIdentifier.fromPrincipal(msg.caller, null);
    };

    //Motoko Timer API
    
    private stable var cron : Timer.TimerId = Timer.setTimer(#seconds (30*60), burn_cron);
    public func kill_cron() : async (){
        let c = Timer.cancelTimer(cron);
    };
};
