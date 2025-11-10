"use client";

import { MAX_UPFRONT_FEE } from "@/src/constants";
import { getProtocolContract } from "@/src/contracts";
import { getBranch } from "@/src/liquity-utils";
import { Button, InputField } from "@liquity2/uikit";
import { useMemo, useState } from "react";
import { erc20Abi, formatUnits, isAddressEqual, maxUint256, parseAbi, parseUnits } from "viem";
import { useAccount, useConfig, useWriteContract } from "wagmi";
import { readContract, readContracts, simulateContract, waitForTransactionReceipt } from "wagmi/actions";

const wrappedSagaTokenAddress = "0xaa5e2ea42f0a9c3b43f2b7d26eaa2ba17ae41dac";

export default function RawBorrowPage() {
  const [collAmountInput, setCollAmountInput] = useState<string>("");
  const [boldAmountInput, setBoldAmountInput] = useState<string>("");
  const [annualInterestRateInput, setAnnualInterestRateInput] = useState<string>("");

  const { address: owner } = useAccount();
  const { writeContractAsync } = useWriteContract();
  const config = useConfig();

  const branch = getBranch("SAGA")
  const hintHelper = getProtocolContract("HintHelpers")

  const collAmount = useMemo(() => {
    if (!collAmountInput) return { raw: 0n, wrapped: 0n };
    return { raw: parseUnits(collAmountInput, 6), wrapped: parseUnits(collAmountInput, 18) };
  }, [collAmountInput]);

  const boldAmount = useMemo(() => {
    if (!boldAmountInput) return 0n;
    return parseUnits(boldAmountInput, 18);
  }, [boldAmountInput]);

  const annualInterestRate = useMemo(() => {
    if (!annualInterestRateInput) return 0n;
    return parseUnits(annualInterestRateInput, 16);
  }, [annualInterestRateInput]);

  if (!branch) {
    return <div>Branch not found</div>;
  }

  getBranchInfo();

  async function getBranchInfo() {
    const results = await readContracts(config, {
      contracts: [
        {
          ...branch.contracts.BorrowerOperations,
          functionName: "hasBeenShutDown"
        },
        {
          ...branch.contracts.TroveManager,
          functionName: "shutdownTime",
        },
        {
          ...branch.contracts.TroveManager,
          functionName: "debtLimit",
        },
        {
          ...branch.contracts.TroveManager,
          functionName: "borrowerOperations"
        },
        {
          ...branch.contracts.ActivePool,
          functionName: "collToken"
        },
        {
          ...branch.contracts.ActivePool,
          functionName: "boldToken"
        },
        {
          ...branch.contracts.ActivePool,
          functionName: "borrowerOperationsAddress"
        },
        {
          ...branch.contracts.TroveManager,
          functionName: "isActive"
        }
      ],
      allowFailure: false
    })
    console.log({
      hasBeenShutDown: results[0],
      shutdownTime: results[1],
      debtLimit: results[2],
      borrowerOperations: results[3],
      collToken: results[4],
      boldToken: results[5],
      borrowerOperationsAddress: results[6],
      isCorrectBO: isAddressEqual(results[3], branch.contracts.BorrowerOperations.address),
      isCorrectCollToken: isAddressEqual(results[4], branch.contracts.CollToken.address) || isAddressEqual(results[4], wrappedSagaTokenAddress),
      isCorrectBorrowerOperationsAddress: isAddressEqual(results[6], branch.contracts.BorrowerOperations.address),
      isActive: results[7],
    });
    return results;
  }

  async function sendZeroAmount() {
    try {
      const simulation = await simulateContract(config, {
        address: wrappedSagaTokenAddress,
        abi: erc20Abi,
        functionName: "transfer",
        args: [
          branch.contracts.BorrowerOperations.address as `0x${string}`,
          0n,
        ],
      });
      console.log("Simulation:", simulation);
    } catch (error) {
      console.error(error);
    }
  }

  async function handleBorrow() {
    try {
      console.log("Owner:", owner);
      console.log("Coll Amount:", collAmount.raw);
      console.log("Wrapped Coll Amount:", collAmount.wrapped);
      console.log("Bold Amount:", boldAmount);
      console.log("Annual Interest Rate:", annualInterestRate);
      console.log("Max Upfront Fee:", MAX_UPFRONT_FEE);

      const wsagaBalance = await readContract(config, {
        address: wrappedSagaTokenAddress,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [owner as `0x${string}`],
      });
      console.log("wSAGA Balance:", formatUnits(wsagaBalance, 18));
      console.log("Sufficient balance:", wsagaBalance >= collAmount.wrapped);
      if (wsagaBalance < collAmount.wrapped) {
        // Approve SAGA to be deposited for wSAGA
        console.log("Approving SAGA to be deposited for wSAGA")
        const approveHash = await writeContractAsync({
          ...branch.contracts.CollToken,
          functionName: "approve",
          args: [wrappedSagaTokenAddress, collAmount.raw],
        });
        const approveReceipt = await waitForTransactionReceipt(config, { hash: approveHash });
        console.log("Approve Receipt:", approveReceipt);
        
        // Simulate depositFor
        console.log("Wrapping SAGA to wSAGA")
        const simulation = await simulateContract(config, {
          address: wrappedSagaTokenAddress,
          abi: parseAbi([
            "function depositFor(address account, uint256 amount) public returns (bool)",
          ]),
          functionName: "depositFor",
          args: [owner as `0x${string}`, collAmount.raw],
        });
        console.log("Simulation:", simulation);
  
        // Deposit SAGA for wSAGA
        const wrapHash = await writeContractAsync({
          address: wrappedSagaTokenAddress,
          abi: parseAbi([
            "function depositFor(address account, uint256 amount) public returns (bool)",
          ]),
          functionName: "depositFor",
          args: [owner as `0x${string}`, collAmount.raw],
        });
        const wrapReceipt = await waitForTransactionReceipt(config, { hash: wrapHash });
        console.log(wrapReceipt);
      }

      const allowance = await readContract(config, {
        address: wrappedSagaTokenAddress,
        abi: erc20Abi,
        functionName: "allowance",
        args: [owner as `0x${string}`, branch.contracts.BorrowerOperations.address],
      });
      console.log("Allowance:", allowance);
      console.log("Allowance >= Coll Amount:", allowance >= collAmount.wrapped);
      if (allowance < collAmount.wrapped) {
        // Approve wSAGA to be deposited as collateral by BorrowerOperations
        console.log("Approving wSAGA to be deposited as collateral by BorrowerOperations")
        const approveHash = await writeContractAsync({
          address: wrappedSagaTokenAddress,
          abi: erc20Abi,
          functionName: "approve",
          args: [branch.contracts.BorrowerOperations.address, collAmount.wrapped],
        });
        const approveReceipt = await waitForTransactionReceipt(config, { hash: approveHash });
        console.log("Approve Receipt:", approveReceipt);
      }
      

      const [ccr, mcr, price, upfrontFee] = await readContracts(config, {
        allowFailure: false,
        contracts: [
          {
            ...branch.contracts.BorrowerOperations,
            functionName: "CCR",
          },
          {
            ...branch.contracts.BorrowerOperations,
            functionName: "MCR",
          },
          {
            ...branch.contracts.PriceFeed,
            functionName: "fetchPrice",
          },
          {
            ...hintHelper,
            functionName: "predictOpenTroveUpfrontFee",
            args: [
              BigInt(branch.id),
              boldAmount,
              annualInterestRate,
            ],
          }
        ]
      })

      console.log("CCR:", ccr);
      console.log("MCR:", mcr);
      console.log("Price:", price);
      console.log("Upfront Fee:", upfrontFee);

      const icr = collAmount.wrapped * price[0] / (boldAmount + upfrontFee)

      console.log("ICR:", icr);
      console.log("ICR > MCR:", icr > mcr);
      console.log("ICR > CCR:", icr > ccr);

      // openTrove in BorrowerOperations
      console.log("Opening trove with owner:", owner);
      // Simulate openTrove
      const openTroveSimulation = await simulateContract(config, {
        address: branch.contracts.BorrowerOperations.address,
        abi: branch.contracts.BorrowerOperations.abi,
        functionName: "openTrove",
        args: [
          owner as `0x${string}`,
          0n,
          collAmount.wrapped,
          boldAmount,
          0n,
          0n,
          annualInterestRate,
          maxUint256,
          owner as `0x${string}`,
          owner as `0x${string}`,
          owner as `0x${string}`,
        ],
      });
      console.log("Simulation:", openTroveSimulation);

      // Open trove
      const hash = await writeContractAsync({
        address: branch.contracts.BorrowerOperations.address,
        abi: [...branch.contracts.BorrowerOperations.abi, ...erc20Abi],
        functionName: "openTrove",
        args: [
          owner as `0x${string}`,
          0n,
          collAmount.wrapped,
          boldAmount,
          0n,
          0n,
          annualInterestRate,
          maxUint256,
          owner as `0x${string}`,
          owner as `0x${string}`,
          owner as `0x${string}`,
        ],
      });
      const receipt = await waitForTransactionReceipt(config, { hash });
      console.log(receipt);
    } catch (error) {
      console.error(error);
    }
  }
  
  return (
    <div>
      <div>
        <InputField
          label="Coll Amount"
          value={collAmountInput}
          onChange={(value) => setCollAmountInput(value)}
        />
        <InputField
          label="Bold Amount"
          value={boldAmountInput}
          onChange={(value) => setBoldAmountInput(value)}
        />
        <InputField
          label="Annual Interest Rate"
          value={annualInterestRateInput}
          onChange={(value) => setAnnualInterestRateInput(value)}
        />
        <Button label="Borrow" onClick={handleBorrow} mode="primary" />
        <Button label="Send Zero Amount" onClick={sendZeroAmount} mode="primary" />
      </div>
    </div>
  );
}