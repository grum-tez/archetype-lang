import * as ex from "@completium/experiment-ts";
import * as att from "@completium/archetype-ts-types";
const exec_arg_to_mich = (): att.Micheline => {
    return att.unit_mich;
}
export class Ticket_fun_split_ticket {
    address: string | undefined;
    constructor(address: string | undefined = undefined) {
        this.address = address;
    }
    get_address(): att.Address {
        if (undefined != this.address) {
            return new att.Address(this.address);
        }
        throw new Error("Contract not initialised");
    }
    async get_balance(): Promise<att.Tez> {
        if (null != this.address) {
            return await ex.get_balance(new att.Address(this.address));
        }
        throw new Error("Contract not initialised");
    }
    async deploy(params: Partial<ex.Parameters>) {
        const address = (await ex.deploy("../tests/passed/ticket_fun_split_ticket.arl", {}, params)).address;
        this.address = address;
    }
    async exec(params: Partial<ex.Parameters>): Promise<att.CallResult> {
        if (this.address != undefined) {
            return await ex.call(this.address, "exec", exec_arg_to_mich(), params);
        }
        throw new Error("Contract not initialised");
    }
    async get_exec_param(params: Partial<ex.Parameters>): Promise<att.CallParameter> {
        if (this.address != undefined) {
            return await ex.get_call_param(this.address, "exec", exec_arg_to_mich(), params);
        }
        throw new Error("Contract not initialised");
    }
    async get_res(): Promise<att.Option<[
        att.Ticket<string>,
        att.Ticket<string>
    ]>> {
        if (this.address != undefined) {
            const storage = await ex.get_raw_storage(this.address);
            return att.Option.from_mich(storage, x => { return (p => {
                return [att.Ticket.from_mich((p as att.Mpair).args[0], x => { return att.mich_to_string(x); }), att.Ticket.from_mich(att.pair_to_mich((p as att.Mpair as att.Mpair).args.slice(1, 4)), x => { return att.mich_to_string(x); })];
            })(x); });
        }
        throw new Error("Contract not initialised");
    }
    errors = {
        ERROR: att.string_to_mich("\"ERROR\"")
    };
}
export const ticket_fun_split_ticket = new Ticket_fun_split_ticket();
