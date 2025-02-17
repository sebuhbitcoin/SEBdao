## API Report File for "basedao-sdk"

> Do not edit this file. It is a report generated by [API Extractor](https://api-extractor.com/).

```ts

// @public (undocumented)
export type Accept_ownership = {};

// @public (undocumented)
export interface Balance_of {
    // (undocumented)
    callback: string;
    // (undocumented)
    requests: Balance_ofRequests;
}

// @public (undocumented)
export type Balance_ofRequests = Array<Balance_ofRequestsItem>;

// @public (undocumented)
export interface Balance_ofRequestsItem {
    // (undocumented)
    owner: string;
    // (undocumented)
    token_id: number;
}

// @public
export class BaseDAOContract {
    constructor(nodeAddr: string, senderSk: string, contractAddr: string);
    // (undocumented)
    accept_ownership(): Promise<string | void>;
    // (undocumented)
    balance_of(arg: Balance_of): Promise<string | void>;
    // (undocumented)
    burn(arg: Burn): Promise<string | void>;
    // (undocumented)
    call_custom(arg: CallCustom): Promise<string | void>;
    // (undocumented)
    confirm_migration(): Promise<string | void>;
    // (undocumented)
    debug: boolean;
    // (undocumented)
    drop_proposal(arg: Drop_proposal): Promise<string | void>;
    // (undocumented)
    flush(arg: Flush): Promise<string | void>;
    // (undocumented)
    get_total_supply(arg: Get_total_supply): Promise<string | void>;
    // (undocumented)
    getVotePermitCounter(arg: GetVotePermitCounter): Promise<string | void>;
    // (undocumented)
    inspectParameter(): void;
    // (undocumented)
    lastOperationHash: undefined | string;
    // (undocumented)
    migrate(arg: Migrate): Promise<string | void>;
    // (undocumented)
    mint(arg: Mint): Promise<string | void>;
    // (undocumented)
    propose(arg: Propose): Promise<string | void>;
    // (undocumented)
    set_quorum_threshold(arg: Set_quorum_threshold): Promise<string | void>;
    // (undocumented)
    set_voting_period(arg: Set_voting_period): Promise<string | void>;
    // (undocumented)
    startup(arg: Startup): Promise<string | void>;
    // (undocumented)
    transfer(arg: Transfer): Promise<string | void>;
    // (undocumented)
    transfer_contract_tokens(arg: Transfer_contract_tokens): Promise<string | void>;
    // (undocumented)
    transfer_ownership(arg: Transfer_ownership): Promise<string | void>;
    // (undocumented)
    update_operators(arg: Update_operators): Promise<string | void>;
    // (undocumented)
    vote(arg: Vote): Promise<string | void>;
    }

// @public (undocumented)
export interface Burn {
    // (undocumented)
    amount: number;
    // (undocumented)
    from_: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export type CallCustom = [string, string];

// @public (undocumented)
export type Confirm_migration = {};

// @public (undocumented)
export type Drop_proposal = string;

// @public (undocumented)
export type Flush = number;

// @public (undocumented)
export interface Get_total_supply {
    // (undocumented)
    viewCallbackTo: string;
    // (undocumented)
    viewParam: number;
}

// @public (undocumented)
export interface GetVotePermitCounter {
    // (undocumented)
    viewCallbackTo: string;
    // (undocumented)
    viewParam: {};
}

// @public (undocumented)
export type Migrate = string;

// @public (undocumented)
export interface Mint {
    // (undocumented)
    amount: number;
    // (undocumented)
    to_: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export interface Propose {
    // (undocumented)
    frozen_token: number;
    // (undocumented)
    proposal_metadata: ProposeProposal_metadata;
}

// @public (undocumented)
export type ProposeProposal_metadata = Map<string, string>;

// @public (undocumented)
export type Set_quorum_threshold = number;

// @public (undocumented)
export type Set_voting_period = number;

// @public (undocumented)
export type Startup = null | StartupItem;

// @public (undocumented)
export type StartupItem = [string, StartupItem1];

// @public (undocumented)
export type StartupItem1 = null | string;

// @public (undocumented)
export type Transfer = Array<TransferItem>;

// @public (undocumented)
export interface Transfer_contract_tokens {
    // (undocumented)
    contract_address: string;
    // (undocumented)
    params: Transfer_contract_tokensParams;
}

// @public (undocumented)
export type Transfer_contract_tokensParams = Array<Transfer_contract_tokensParamsItem>;

// @public (undocumented)
export interface Transfer_contract_tokensParamsItem {
    // (undocumented)
    from_: string;
    // (undocumented)
    txs: Transfer_contract_tokensParamsItemTxs;
}

// @public (undocumented)
export type Transfer_contract_tokensParamsItemTxs = Array<Transfer_contract_tokensParamsItemTxsItem>;

// @public (undocumented)
export interface Transfer_contract_tokensParamsItemTxsItem {
    // (undocumented)
    amount: number;
    // (undocumented)
    to_: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export type Transfer_ownership = string;

// @public (undocumented)
export interface TransferItem {
    // (undocumented)
    from_: string;
    // (undocumented)
    txs: TransferItemTxs;
}

// @public (undocumented)
export type TransferItemTxs = Array<TransferItemTxsItem>;

// @public (undocumented)
export interface TransferItemTxsItem {
    // (undocumented)
    amount: number;
    // (undocumented)
    to_: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export type Update_operators = Array<Update_operatorsItem>;

// @public (undocumented)
export type Update_operatorsItem = Update_operatorsItemAdd_operator | Update_operatorsItemRemove_operator;

// @public (undocumented)
export interface Update_operatorsItemAdd_operator {
    // (undocumented)
    add_operator: Update_operatorsItemAdd_operatorItem;
}

// @public (undocumented)
export interface Update_operatorsItemAdd_operatorItem {
    // (undocumented)
    operator: string;
    // (undocumented)
    owner: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export interface Update_operatorsItemRemove_operator {
    // (undocumented)
    remove_operator: Update_operatorsItemRemove_operatorItem;
}

// @public (undocumented)
export interface Update_operatorsItemRemove_operatorItem {
    // (undocumented)
    operator: string;
    // (undocumented)
    owner: string;
    // (undocumented)
    token_id: number;
}

// @public (undocumented)
export type Vote = Array<VoteItem>;

// @public (undocumented)
export interface VoteItem {
    // (undocumented)
    proposal_key: string;
    // (undocumented)
    vote_amount: number;
    // (undocumented)
    vote_type: boolean;
    // (undocumented)
    permit?: VoteItemPermit;
}

// @public (undocumented)
export interface VoteItemPermit {
    // (undocumented)
    key: string;
    // (undocumented)
    signature: string;
}


// (No @packageDocumentation comment for this package)

```
