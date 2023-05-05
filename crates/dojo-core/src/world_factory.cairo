use array::ArrayTrait;

#[contract]
mod WorldFactory {
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;

    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressIntoFelt252;
    use starknet::syscalls::deploy_syscall;

    use dojo_core::interfaces::IWorldDispatcher;
    use dojo_core::interfaces::IWorldDispatcherTrait;
    use dojo_core::string::ShortString;

    struct Storage {
        world_class_hash: ClassHash,
        executor_address: ContractAddress,
    }

    #[event]
    fn WorldSpawned(address: ContractAddress) {}

    #[constructor]
    fn constructor(world_class_hash_: ClassHash, executor_address_: ContractAddress) {
        world_class_hash::write(world_class_hash_);
        executor_address::write(executor_address_);
    }

    #[external]
    fn spawn(name: ShortString, components: Array::<ClassHash>, systems: Array::<ClassHash>) -> ContractAddress {
        // deploy world
        let mut world_constructor_calldata: Array<felt252> = ArrayTrait::new();
        world_constructor_calldata.append(name.into());
        world_constructor_calldata.append(executor_address::read().into());
        let world_class_hash = world_class_hash::read();
        let result = deploy_syscall(world_class_hash, 0, world_constructor_calldata.span(), true);
        let (world_address, _) = result.unwrap_syscall();

        // events
        WorldSpawned(world_address);

        // register components
        let components_len = components.len();
        register_components(components, components_len, 0_usize, world_address);

        // register systems
        let systems_len = systems.len();
        register_systems(systems, systems_len, 0_usize, world_address);

        return world_address;
    }

    #[external]
    fn set_executor(executor_address_: ContractAddress) {
        executor_address::write(executor_address_);
    }

    #[external]
    fn set_world(class_hash: ClassHash) {
        world_class_hash::write(class_hash);
    }

    #[view]
    fn executor() -> ContractAddress {
        return executor_address::read();
    }

    #[view]
    fn world() -> ClassHash {
        return world_class_hash::read();
    }

    fn register_components(
        components: Array<ClassHash>,
        components_len: usize,
        index: usize,
        world_address: ContractAddress
    ) {
        gas::withdraw_gas().expect('Out of gas');
        if (index == components_len) {
            return ();
        }
        IWorldDispatcher {
            contract_address: world_address
        }.register_component(*components.at(index));
        return register_components(components, components_len, index + 1_usize, world_address);
    }

    fn register_systems(
        systems: Array<ClassHash>, systems_len: usize, index: usize, world_address: ContractAddress
    ) {
        gas::withdraw_gas().expect('Out of gas');
        if (index == systems_len) {
            return ();
        }
        IWorldDispatcher { contract_address: world_address }.register_system(*systems.at(index));
        return register_systems(systems, systems_len, index + 1_usize, world_address);
    }
}